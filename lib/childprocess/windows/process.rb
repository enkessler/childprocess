module ChildProcess
  module Windows
    class Process < AbstractProcess

      def stop(timeout = 3)
        assert_started

        # just kill right away on windows.
        log "sending KILL"
        @handle.send(WIN_SIGKILL)
        
        poll_for_exit(timeout)
      ensure
        @handle.close
      end

      def exited?
        if @exit_code
          return true
        else
          assert_started
          code   = @handle.exit_code
          exited = code != PROCESS_STILL_ACTIVE
          
          if exited
            @exit_code = code
          end
            
          exited
        end
      end

      private

      def launch_process
        @pid    = Lib.create_proc(@args.join(' '), :inherit => false)
        @handle = Handle.open(@pid)

        self
      end

    end # Process
  end # Windows
end # ChildProcess
