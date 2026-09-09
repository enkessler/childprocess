# frozen_string_literal: true

require 'childprocess/version'
require 'childprocess/errors'
require 'childprocess/abstract_process'
require 'childprocess/abstract_io'
require 'childprocess/process_spawn_process'
require 'fcntl'
require 'logger'

#
# A simple and reliable solution for controlling external programs running
# in the background on any Ruby / OS combination.
#
# @example Basic usage
#   process = ChildProcess.build("ruby", "-e", "sleep")
#   process.io.inherit!
#   process.start
#   process.poll_for_exit(10)
#
# @see ChildProcess.build the main entry point
module ChildProcess
  @posix_spawn = false

  class << self
    # @return [Logger] the logger used for internal debug/warning messages;
    #   defaults to a {Logger} writing to `$stderr`
    attr_writer :logger

    #
    # Set this to true to enable experimental use of posix_spawn.
    #
    # @return [Boolean]
    attr_writer :posix_spawn

    #
    # Build a new child process for the given command and arguments,
    # choosing the concrete {AbstractProcess} subclass appropriate for the
    # current platform ({Unix::Process} or {Windows::Process}). Also
    # available as {.build}.
    #
    # The command is never run through a shell -- e.g. shell built-ins,
    # globbing and `.bat`/`.com` extensions on Windows won't work unless
    # you invoke the relevant interpreter explicitly (`"cmd.exe", "/c",
    # "..."` or `"ruby", "-S", "..."`).
    #
    # @param args [Array<String>] the command and its arguments
    # @raise [ArgumentError] if any argument is not a String
    # @raise [Error] if the current platform isn't supported
    # @return [AbstractProcess]

    # rubocop:disable-next Style/ArgumentsForwarding -- named for the sake of the @param doc above
    def new(*args)
      case os
      when :macosx, :linux, :solaris, :bsd, :cygwin, :aix
        Unix::Process.new(*args)
      when :windows
        Windows::Process.new(*args)
      else
        raise Error, "unsupported platform #{platform_name.inspect}"
      end
    end
    alias build new

    #
    # @return [Logger] the logger used for internal debug/warning messages

    def logger
      return @logger if defined?(@logger) && @logger

      @logger = Logger.new($stderr)
      @logger.level = $DEBUG ? Logger::DEBUG : Logger::INFO

      @logger
    end

    #
    # @return [Symbol] the detected OS, same as {.os}

    def platform
      os
    end

    #
    # @return [String] the detected architecture and OS, e.g. `"x86_64-linux"`

    def platform_name
      @platform_name ||= "#{arch}-#{os}"
    end

    #
    # @return [Boolean] `true` unless running on Windows

    def unix?
      !windows?
    end

    #
    # @return [Boolean] `true` if running on Linux

    def linux?
      os == :linux
    end

    #
    # @return [Boolean] `true` if running under the JRuby engine

    def jruby?
      RUBY_ENGINE == 'jruby'
    end

    #
    # @return [Boolean] `true` if running on Windows

    def windows?
      os == :windows
    end

    #
    # Whether {.posix_spawn=} was set to `true`, or the
    # `CHILDPROCESS_POSIX_SPAWN` environment variable is `"1"` or `"true"`.
    #
    # @return [Boolean]

    def posix_spawn_chosen_explicitly?
      @posix_spawn || %w[1 true].include?(ENV.fetch('CHILDPROCESS_POSIX_SPAWN', nil))
    end

    #
    # ChildProcess 5+ always uses `Process.spawn` and has no separate
    # posix_spawn backend; kept for backwards API compatibility with
    # earlier ChildProcess versions.
    #
    # @return [Boolean] always `false`

    def posix_spawn?
      false
    end

    #
    # @return [Symbol] the detected OS, one of `:macosx`, `:linux`,
    #   `:windows`, `:cygwin`, `:solaris`, `:bsd`, `:aix`
    # @raise [Error] if the OS could not be determined

    def os
      return :windows if ENV['FAKE_WINDOWS'] == 'true'

      @os ||= begin
        require 'rbconfig'
        host_os = RbConfig::CONFIG['host_os'].downcase

        case host_os
        when /linux/
          :linux
        when /darwin|mac os/
          :macosx
        when /mswin|msys|mingw32/
          :windows
        when /cygwin/
          :cygwin
        when /solaris|sunos/
          :solaris
        when /bsd|dragonfly/
          :bsd
        when /aix/
          :aix
        else
          raise Error, "unknown os: #{host_os.inspect}"
        end
      end
    end

    #
    # @return [String] the detected CPU architecture, e.g. `"x86_64"`, `"i386"`, `"powerpc"`

    def arch
      @arch ||= begin
        host_cpu = RbConfig::CONFIG['host_cpu'].downcase
        case host_cpu
        when /i[3456]86/
          if workaround_older_macosx_misreported_cpu?
            # Workaround case: older 64-bit Darwin Rubies misreported as i686
            'x86_64'
          else
            'i386'
          end
        when /amd64|x86_64/
          'x86_64'
        when /ppc|powerpc/
          'powerpc'
        else
          host_cpu
        end
      end
    end

    #
    # By default, a child process will inherit open file descriptors from the
    # parent process. This helper provides a cross-platform way of making sure
    # that doesn't happen for the given file/io.
    #
    # @param file [IO] the file/IO to set close-on-exec for
    # @raise [Error] if `file` doesn't respond to `close_on_exec=`
    # @return [void]

    def close_on_exec(file)
      unless file.respond_to?(:close_on_exec=)
        raise Error, "not sure how to set close-on-exec for #{file.inspect} on #{platform_name.inspect}"
      end

      file.close_on_exec = true
    end

    private

    # Workaround: detect the situation that an older Darwin Ruby is actually
    # 64-bit, but is misreporting cpu as i686, which would imply 32-bit.
    #
    # @return [Boolean] `true` if:
    #   (a) on Mac OS X
    #   (b) actually running in 64-bit mode
    def workaround_older_macosx_misreported_cpu?
      os == :macosx && is_64_bit?
    end

    # @return [Boolean] `true` if this Ruby represents `1` in 64 bits (8 bytes).
    def is_64_bit?
      1.size == 8
    end
  end
end

# simplecov:disable
# Exactly one of these two branches can ever execute for a given OS/process,
# so this platform dispatch can never show 100% branch coverage from a
# single test run (regardless of which OS runs the suite).
if ChildProcess.windows?
  require 'childprocess/windows'
else
  require 'childprocess/unix'
end
# simplecov:enable
