module ChildProcess
  module Windows
    class << self
      def kill(signal, *pids)
        case signal
        when 'SIGINT', 'INT', :SIGINT, :INT
          signal = WIN_SIGINT
        when 'SIGBRK', 'BRK', :SIGBREAK, :BRK
          signal = WIN_SIGBREAK
        when 'SIGKILL', 'KILL', :SIGKILL, :KILL
          signal = WIN_SIGKILL
        when 0..9
          # Do nothing
        else
          raise Error, "invalid signal #{signal.inspect}"
        end

        pids.map { |pid| pid if send_signal(signal, pid) }.compact
      end

      def waitpid(pid, flags = 0)
        wait_for_pid(pid, no_hang?(flags))
      end

      def waitpid2(pid, flags = 0)
        code = wait_for_pid(pid, no_hang?(flags))

        [pid, code] if code
      end

      private

      def no_hang?(flags)
        (flags & Process::WNOHANG) == Process::WNOHANG
      end

      def wait_for_pid(pid, no_hang)
        code = Handle.open(pid) { |handle|
          handle.wait unless no_hang
          handle.exit_code
        }

        code if code != PROCESS_STILL_ACTIVE
      end

    end # class << self
  end # Windows
end # ChildProcess
