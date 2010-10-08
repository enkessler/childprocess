module ChildProcess
  autoload :Unix,     "childprocess/unix"
  autoload :Windows,  "childprocess/windows"
  autoload :JRuby,    "childprocess/jruby"
  autoload :IronRuby, "childprocess/ironruby"

  class Error < StandardError; end
  class TimeoutError < StandardError; end
  class SubclassResponsibility < StandardError; end

  def self.build(*args)
    case platform
    when :jruby
      JRuby::Process.new(args)
    when :ironruby
      IronRuby::Process.new(args)
    when :windows
      Windows::Process.new(args)
    else
      Unix::Process.new(args)
    end
  end

  def self.platform
    if RUBY_PLATFORM == "java"
      :java
    elsif defined?(RUBY_ENGINE) && RUBY_ENGINE == "ironruby"
      :ironruby
    elsif RUBY_PLATFORM =~ /mswin|msys|mingw32/
      :windows
    end
  end

  class AbstractProcess
    attr_reader :exit_code

    def initialize(args)
      @args      = args
      @started   = false
      @exit_code = nil
    end

    #
    # Launch the child process
    #
    # @return [AbstractProcess] self
    #

    def start
      launch_process
      @started = true

      self
    end

    #
    # Forcibly terminate the process, using increasingly harsher methods if possible.
    #
    # @param [Fixnum] timeout (3) Seconds to wait before trying the next method.
    #

    def stop(timeout = 3)
      raise SubclassResponsibility
    end

    #
    # Did the process exit?
    #
    # @return [Boolean]
    #

    def exited?
      raise SubclassResponsibility
    end

    #
    # Is this process running?
    #

    def alive?
      started? && !exited?
    end

    private

    def launch_process
      raise SubclassResponsibility
    end

    POLL_INTERVAL = 0.1

    def poll_for_exit(timeout)
      log "polling #{timeout} seconds for exit"

      end_time = Time.now + timeout
      until exited? || Time.now > end_time
        sleep POLL_INTERVAL
      end

      unless exited?
        raise TimeoutError, "process still alive after #{timeout} seconds"
      end
    end

    def started?
      @started
    end

    def log(msg)
      $stderr.puts "#{self.inspect}: #{msg}" if $DEBUG
    end

    def assert_started
      raise Error, "process not started" unless started?
    end

  end # AbstractProcess
end # ChildProcess