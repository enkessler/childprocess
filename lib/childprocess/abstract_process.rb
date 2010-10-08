module ChildProcess
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
      raise SubclassResponsibility, "stop"
    end

    #
    # Did the process exit?
    #
    # @return [Boolean]
    #

    def exited?
      raise SubclassResponsibility, "exited?"
    end

    #
    # Is this process running?
    #

    def alive?
      started? && !exited?
    end
    
    def crashed?
      @exit_code && @exit_code != 0
    end

    def poll_for_exit(timeout)
      log "polling #{timeout} seconds for exit"

      end_time = Time.now + timeout
      until (ok = exited?) || Time.now > end_time
        sleep POLL_INTERVAL
      end

      unless ok
        raise TimeoutError, "process still alive after #{timeout} seconds"
      end
    end

    private

    def launch_process
      raise SubclassResponsibility, "launch_process"
    end

    POLL_INTERVAL = 0.1

    def started?
      @started
    end

    def log(*args)
      $stderr.puts "#{self.inspect} : #{args.inspect}" if $DEBUG
    end

    def assert_started
      raise Error, "process not started" unless started?
    end

  end # AbstractProcess
end # ChildProcess