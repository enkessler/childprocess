# frozen_string_literal: true

require_relative 'abstract_process'

module ChildProcess
  # {AbstractProcess} implementation shared by {Unix::Process} and
  # {Windows::Process}, built entirely on Ruby's core `Process.spawn` /
  # `Process.waitpid2` / `Process.kill` for maximum portability. `#stop`
  # (the only genuinely platform-specific behavior -- which signal(s) to
  # try, and in what order) is implemented by the two subclasses.
  class ProcessSpawnProcess < AbstractProcess
    # @return [Integer] the pid of the process, once started
    attr_reader :pid

    #
    # @return [Boolean] whether the process has exited

    def exited?
      return true if @exit_code

      assert_started
      pid, status = ::Process.waitpid2(@pid, ::Process::WNOHANG | ::Process::WUNTRACED)
      pid = nil if pid&.zero? # may happen on jruby; pid is also nil while the process is still running

      log(pid: pid, status: status)

      set_exit_code(status) if pid

      !!pid
    rescue Errno::ECHILD
      # may be thrown for detached processes
      true
    end

    #
    # @return [Integer] the exit status of the process, blocking until it exits

    def wait
      assert_started

      if exited?
        exit_code
      else
        _, status = ::Process.waitpid2(@pid)

        set_exit_code(status)
      end
    end

    private

    def launch_process
      options = base_spawn_options

      if duplex?
        reader, writer = ::IO.pipe
        options[:in] = reader.fileno
        options[writer.fileno] = :close unless ChildProcess.windows?
      end

      begin
        @pid = ::Process.spawn(sanitized_environment, *spawn_args, options)
      rescue SystemCallError => e
        raise LaunchError, e.message
      end

      if duplex?
        io._stdin = writer
        reader.close
      end

      ::Process.detach(@pid) if detach?
    end

    # The base set of options passed to ::Process.spawn: where to send the
    # child's stdout/stderr, its process-group behavior, and its cwd. Any
    # duplex (stdin pipe) options are added separately by #launch_process,
    # since they involve state (the pipe's reader/writer) that's also
    # needed after the process has been spawned.
    def base_spawn_options
      options = {
        out: io.stdout ? io.stdout.fileno : File::NULL,
        err: io.stderr ? io.stderr.fileno : File::NULL
      }

      if leader?
        if ChildProcess.windows?
          options[:new_pgroup] = true
        else
          options[:pgroup] = true
        end
      end

      options[:chdir] = @cwd if @cwd

      options
    end

    # Stringifies the configured environment, rejecting anything that
    # ::Process.spawn's underlying execve(2) call can't represent.
    def sanitized_environment
      @environment.each_with_object({}) do |(key, value), environment|
        key = key.to_s
        value = value&.to_s

        if key.include?("\0") || key.include?('=') || value.to_s.include?("\0")
          raise InvalidEnvironmentVariable, "#{key.inspect} => #{value.to_s.inspect}"
        end

        environment[key] = value
      end
    end

    def spawn_args
      return @args unless @args.size == 1

      # When given a single String, Process.spawn would think it should use the shell
      # if there is any special character in it. However, ChildProcess should never
      # use the shell. So we use the [cmdname, argv0] form to force no shell.
      arg = @args[0]
      [[arg, arg]]
    end

    # Records the process's exit status as {AbstractProcess#exit_code}: the
    # exit code if it exited normally, or the signal number if it was
    # killed by a signal.
    def set_exit_code(status)
      @exit_code = status.exitstatus || status.termsig
    end

    def send_term
      send_signal 'TERM'
    end

    def send_kill
      send_signal 'KILL'
    end

    # Sends `sig` to the process. If it's the {AbstractProcess#leader} of a
    # process group, the whole group is targeted: on Unix via a negative
    # pid passed to `Process.kill`, on Windows by shelling out to
    # `taskkill /T` (there is no direct Ruby API for killing a Windows
    # process tree).
    def send_signal(sig)
      assert_started

      log "sending #{sig}"
      if leader?
        if ChildProcess.unix?
          ::Process.kill sig, -@pid # negative pid == process group
        else
          output = `taskkill /F /T /PID #{@pid}`
          log output
        end
      else
        ::Process.kill sig, @pid
      end
    end
  end
end
