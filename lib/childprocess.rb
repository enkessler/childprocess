require 'childprocess/errors'
require 'childprocess/abstract_process'
require 'childprocess/abstract_io'
require "fcntl"

module ChildProcess
  autoload :Unix,     'childprocess/unix'
  autoload :Windows,  'childprocess/windows'
  autoload :JRuby,    'childprocess/jruby'

  class << self
    def new(*args)
      case platform
      when :jruby
        JRuby::Process.new(args)
      when :windows
        Windows::Process.new(args)
      when :macosx, :linux, :unix, :cygwin
        if posix_spawn?
          Unix::PosixSpawnProcess.new(args)
        else
          Unix::Process.new(args)
        end
      else
        raise Error, "unsupported platform #{platform.inspect}"
      end
    end
    alias_method :build, :new

    def platform
      if RUBY_PLATFORM == "java"
        :jruby
      elsif defined?(RUBY_ENGINE) && RUBY_ENGINE == "ironruby"
        :ironruby
      elsif RUBY_PLATFORM =~ /mswin|msys|mingw32/
        :windows
      elsif RUBY_PLATFORM =~ /cygwin/
        :cygwin
      else
        os
      end
    end

    def unix?
      !jruby? && [:macosx, :linux, :unix].include?(os)
    end

    def jruby?
      platform == :jruby
    end

    def jruby_on_unix?
      jruby? and [:macosx, :linux, :unix].include? os
    end

    def windows?
      !jruby? && os == :windows
    end

    def posix_spawn?
      @posix_spawn || %w[1 true].include?(ENV['CHILDPROCESS_POSIX_SPAWN'])
    end

    def posix_spawn=(bool)
      @posix_spawn = bool
    end

    def os
      @os ||= (
        require "rbconfig"
        host_os = RbConfig::CONFIG['host_os']

        case host_os
        when /mswin|msys|mingw32|cygwin/
          :windows
        when /darwin|mac os/
          :macosx
        when /linux/
          :linux
        when /solaris|bsd/
          :unix
        else
          raise Error, "unknown os: #{host_os.inspect}"
        end
      )
    end

    #
    # By default, a child process will inherit open file descriptors from the
    # parent process. This helper provides a cross-platform way of making sure
    # that doesn't happen for the given file/io.
    #

    def close_on_exec(file)
      if file.respond_to?(:close_on_exec=)
        file.close_on_exec = true
      elsif file.respond_to?(:fcntl) && defined?(Fcntl::FD_CLOEXEC)
        file.fcntl Fcntl::F_SETFD, Fcntl::FD_CLOEXEC
      elsif windows?
        Windows::Lib.dont_inherit file
      else
        raise Error, "not sure how to set close-on-exec for #{file.inspect} on #{platform.inspect}"
      end
    end

  end # class << self
end # ChildProcess
