module ChildProcess
  module Unix
    class Process < AbstractProcess
      #
      # @return [Fixnum] the pid of the process after it has started
      #
      attr_reader :pid

      def io
        @io ||= Unix::IO.new
      end

      def stop(timeout = 3)
        assert_started
        send_term

        begin
          return poll_for_exit(timeout)
        rescue TimeoutError
          # try next
        end

        send_kill
        wait
      rescue Errno::ECHILD, Errno::ESRCH
        # handle race condition where process dies between timeout
        # and send_kill
        true
      end

      #
      # Did the process exit?
      #
      # @return [Boolean]
      #

      def exited?
        return true if @exit_code

        assert_started
        pid, status = ::Process.waitpid2(@pid, ::Process::WNOHANG)

        log(:pid => pid, :status => status)

        if pid
          @exit_code = status.exitstatus || status.termsig
        end

        !!pid
      end

      #
      # Block until the process has been terminated.
      #
      # @return [FixNum] The exit status of the process
      #

      def wait
        pid, status = ::Process.waitpid2 @pid

        @exit_code = status.exitstatus || status.termsig
      end

      private

      def send_term
        send_signal 'TERM'
      end

      def send_kill
        send_signal 'KILL'
      end

      def send_signal(sig)
        assert_started

        log "sending #{sig}"
        ::Process.kill sig, @pid
      end

      def launch_process
        if @io
          stdout = @io.stdout
          stderr = @io.stderr
        end

        # pipe used to detect exec() failure
        exec_r, exec_w = ::IO.pipe
        ChildProcess.close_on_exec exec_w

        if duplex?
          reader, writer = ::IO.pipe
        end

        @pid = fork {
          exec_r.close
          set_env

          STDOUT.reopen(stdout || "/dev/null")
          STDERR.reopen(stderr || "/dev/null")

          if duplex?
            STDIN.reopen(reader)
            writer.close
          end

          begin
            exec(*@args)
          rescue SystemCallError => ex
            exec_w << ex.message
          end
        }

        exec_w.close

        if duplex?
          io._stdin = writer
          reader.close
        end

        # if we don't eventually get EOF, exec() failed
        unless exec_r.eof?
          raise LaunchError, exec_r.read || "executing command with #{@args.inspect} failed"
        end

        ::Process.detach(@pid) if detach?
      end

      def set_env
        @environment.each { |k, v| ENV[k.to_s] = v.to_s }
      end

    end # Process
  end # Unix
end # ChildProcess
