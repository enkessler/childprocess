module ChildProcess
  module Unix
    class Process < AbstractProcess

      def stop(timeout = 3)
        assert_started
        send_term

        begin
          return poll_wait(timeout)
        rescue TimeoutError
          # try next
        end

        send_kill
        poll_wait(timeout)
      rescue Errno::ECHILD
        # that'll do
        true
      end

      #
      # Did the process exit?
      #
      # @return [Boolean]
      #

      def exited?
        if @exit_code
          true
        else
          assert_started
          pid, status = ::Process.waitpid2(@pid, ::Process::WNOHANG)

          !!(pid && @exit_code = status.exitstatus)
        end
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
        ::Process.kill(sig, @pid)
      end

      def launch_process
        @pid = fork {
          unless $DEBUG
            [STDOUT, STDERR].each { |io| io.reopen("/dev/null") }
          end

          exec(*@args)
        }
      end

    end # Process
  end # Unix
end # ChildProcess
