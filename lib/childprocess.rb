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
        if os == :windows
          Windows::Process.new(args)
        else
          JRuby::Process.new(args)
        end
      when :windows
        Windows::Process.new(args)
      when :macosx, :linux, :unix, :cygwin
        Unix::Process.new(args)
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
      else
        os
      end
    end

    def unix?
      !windows?
    end

    def jruby?
      platform == :jruby
    end

    def windows?
      os == :windows
    end

    def os
      @os ||= (
        require "rbconfig"
        host_os = RbConfig::CONFIG['host_os']

        case host_os
        when /linux/
          :linux
        when /darwin|mac os/
          :macosx
        when /mswin|msys|mingw32/
          :windows
        when /cygwin/
          :cygwin
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

require 'jruby' if ChildProcess.jruby?