module ChildProcess
  module Unix
    class Process < AbstractProcess
      attr_reader :pid

      def io
        @io ||= Unix::IO.new
      end

      def return_unless_timeout
        lambda do |timeout|
          begin
            return poll_for_exit timeout
          rescue TimeoutError
          end
        end
      end

      def stop(timeout = 3, signal=nil)
        assert_started

        unless signal.nil?
          send_signal signal
          return_unless_timeout.call(timeout)
        end

        send_term
        return_unless_timeout.call(timeout)

        send_kill
        wait
      rescue Errno::ECHILD, Errno::ESRCH
        # handle race condition where process dies between timeout
        # and send_kill
        true
      end

      def exited?
        return true if @exit_code

        assert_started
        pid, status = ::Process.waitpid2(@pid, ::Process::WNOHANG)
        pid = nil if pid == 0 # may happen on jruby

        log(:pid => pid, :status => status)

        if pid
          @exit_code = status.exitstatus || status.termsig
        end

        !!pid
      end

      def wait
        assert_started
        _, status = ::Process.waitpid2 @pid

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

    end # Process
  end # Unix
end # ChildProcess
