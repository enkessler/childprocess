# frozen_string_literal: true

require_relative '../process_spawn_process'

module ChildProcess
  module Unix
    # {AbstractProcess} implementation used on Unix-family platforms.
    # {#stop} escalates from `SIGTERM` to `SIGKILL`.
    class Process < ProcessSpawnProcess
      # @return [Unix::IO]
      def io
        @io ||= Unix::IO.new
      end

      #
      # Sends `SIGTERM`, waits up to `timeout` seconds for the process to
      # exit, and sends `SIGKILL` if it hasn't.
      #
      # @param timeout [Numeric] seconds to wait after `SIGTERM` before sending `SIGKILL`
      # @return [Integer, true] the exit status, or `true` if the process
      #   already died in the race between the timeout and `SIGKILL`

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
    end
  end
end
