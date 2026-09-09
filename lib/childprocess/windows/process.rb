# frozen_string_literal: true

require_relative '../process_spawn_process'

module ChildProcess
  module Windows
    # {AbstractProcess} implementation used on Windows. Unlike
    # {Unix::Process}, {#stop} has no graceful-termination signal to send
    # first (Windows has no real equivalent of `SIGTERM`), so it goes
    # straight to a forceful kill.
    class Process < ProcessSpawnProcess
      # @return [Windows::IO]
      def io
        @io ||= Windows::IO.new
      end

      #
      # Forcibly terminates the process and waits up to `timeout` seconds
      # for it to exit.
      #
      # @param timeout [Numeric] seconds to wait for the process to exit after being killed
      # @return [Integer, true] the exit status, or `true` if the process
      #   already died in the race between the timeout and the kill

      def stop(timeout = 3)
        assert_started
        send_kill

        begin
          return poll_for_exit(timeout)
        rescue TimeoutError
          # try next
        end

        wait
      rescue Errno::ECHILD, Errno::ESRCH
        # handle race condition where process dies between timeout
        # and send_kill
        true
      end
    end
  end
end
