module ChildProcess
  module Windows
    class ProcessBuilder
      attr_accessor :inherit, :detach, :duplex, :environment, :stdout, :stderr
      attr_reader :stdin

      def initialize(args)
        @args        = args

        @inherit     = false
        @detach      = false
        @duplex      = false
        @environment = nil

        @stdout      = nil
        @stderr      = nil
        @stdin       = nil

        @flags       = 0
        @cmd_ptr     = nil
        @env_ptr     = nil
      end

      def start
        create_command_pointer
        create_environment_pointer

        setup_detach
        setup_io

        pid = create_process
        close_handles

        pid
      end

      private

      def create_command_pointer
        string = @args.map { |arg| quote_if_necessary(arg.to_s) }.join ' '
        @cmd_ptr = FFI::MemoryPointer.from_string string
      end

      def create_environment_pointer
        return unless @environment.kind_of?(Hash) && @environment.any?

        # inherited env
        strings = ENV.map { |k,v| "#{k}=#{v}\0" }

        # extras
        @environment.each do |key, value|
          if key.include?("=")
            raise InvalidEnvironmentVariableName, key
          end

          strings << "#{key}=#{value}\0"
        end

        strings << "\0" # terminate the env block
        env_str = strings.join

        @env_ptr = FFI::MemoryPointer.new(:long, env_str.bytesize)
        @env_ptr.write_bytes env_str, 0, env_str.bytesize
      end

      def create_process
        ok = Lib.create_process(
          nil,          # application name
          @cmd_ptr,     # command line
          nil,          # process attributes
          nil,          # thread attributes
          @inherit,     # inherit handles
          @flags,       # creation flags
          @env_ptr,     # environment
          nil,          # current directory
          startup_info, # startup info
          process_info  # process info
        )

        ok or raise LaunchError, Lib.last_error_message

        process_info[:dwProcessId]
      end

      def startup_info
        @startup_info ||= StartupInfo.new
      end

      def process_info
        @process_info ||= ProcessInfo.new
      end

      def setup_detach
        @flags |= DETACHED_PROCESS if @detach
      end

      def setup_io
        if @stdout || @stderr
          startup_info[:dwFlags] ||= 0
          startup_info[:dwFlags] |= STARTF_USESTDHANDLES

          @inherit = true

          if @stdout
            startup_info[:hStdOutput] = std_stream_handle_for(@stdout)
          end

          if @stderr
            startup_info[:hStdError] = std_stream_handle_for(@stderr)
          end
        end

        setup_stdin if @duplex
      end

      def setup_stdin
        read_pipe_ptr  = FFI::MemoryPointer.new(:pointer)
        write_pipe_ptr = FFI::MemoryPointer.new(:pointer)
        sa             = SecurityAttributes.new(:inherit => true)

        ok = Lib.create_pipe(read_pipe_ptr, write_pipe_ptr, sa, 0)
        Lib.check_error ok

        @read_pipe  = read_pipe_ptr.read_pointer
        @write_pipe = write_pipe_ptr.read_pointer

        Lib.set_handle_inheritance @write_pipe.address, false

        startup_info[:hStdInput] = @read_pipe
      end

      def close_handles
        Lib.close_handle process_info[:hProcess]
        Lib.close_handle process_info[:hThread]

        if @duplex
          @stdin = Lib.io_for(Lib.duplicate_handle(@write_pipe), File::WRONLY)
          Lib.close_handle @read_pipe
          Lib.close_handle @write_pipe
        end
      end

      def std_stream_handle_for(io)
        handle = Lib.handle_for(io.fileno)

        begin
          Lib.set_handle_inheritance handle, true
        rescue ChildProcess::Error
          # If the IO was set to close on exec previously, this call will fail.
          # That's probably OK, since the user explicitly asked for it to be
          # closed (at least I have yet to find other cases where this will
          # happen...)
        end

        handle
      end

      def quote_if_necessary(str)
        quote = str.start_with?('"') ? "'" : '"'

        case str
        when /[\s\\'"]/
          %{#{quote}#{str}#{quote}}
        else
          str
        end
      end
    end # ProcessBuilder
  end # Windows
end # ChildProcess