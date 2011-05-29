module ChildProcess
  module Windows
    class Process < AbstractProcess
      #
      # @return [Fixnum] the pid of the process after it has started
      #
      attr_reader :pid

      def io
        @io ||= Windows::IO.new
      end

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
        return true if @exit_code
        assert_started

        code   = @handle.exit_code
        exited = code != PROCESS_STILL_ACTIVE

        log(:exited? => exited, :code => code)

        if exited
          @exit_code = code
        end

        exited
      end

      private

      def launch_process
        opts = {
          :inherit => false,
          :detach  => detach?,
          :duplex  => duplex?
        }

        if @io
          opts[:stdout] = @io.stdout
          opts[:stderr] = @io.stderr
        end

        command = get_cmdline_str(@args)

        @pid = Lib.create_proc(command, opts)
        @handle = Handle.open(@pid)

        if duplex?
          io._stdin = opts[:stdin]
        end

        self
      end

      # Get a commandline string from an array
      def get_cmdline_str(args)
          # Build commandline string, with quotes around arguments with special
          # characters in them (i.e., characters interpreted by shell)
          args_str = ""
          quote = '"'
          args.each do |arg|
              if not arg.kind_of?(String)
                  raise RuntimeError, "Argument not string: '#{arg}' (#{arg.class})"
              end

              if arg.nil?
                  next
              end
              # Quote whitespace and '\'
              if not /[\s\\]/.match(arg).nil?
                  arg = "#{quote}#{arg}#{quote}"
              end
              args_str += "#{arg} "
          end
          args_str.strip!()

          return args_str
      end

    end # Process
  end # Windows
end # ChildProcess
