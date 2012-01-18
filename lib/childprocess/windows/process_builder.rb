module ChildProcess
  module Windows
    class ProcessBuilder
      attr_accessor :inherit, :detach, :duplex, :environment, :stdout, :stderr, :app_name
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

        @app_name = nil
        @app_name_ptr = nil
      end

      def start
        create_command_pointers
        create_environment_pointer

        setup_detach
        setup_io

        pid = create_process
        close_handles

        pid
      end

      private

      def create_command_pointers
        string = @args.map { |arg| quote_if_necessary(arg.to_s) }.join ' '

        # .bat file handling, must be run under cmd.exe
        if string && @app_name.nil?
          batch_file = string.match(/'?"?.*\.bat\s?/) ? true : false
          if batch_file
            @app_name = quote_if_necessary(File.join(ENV["WINDIR"], "system32", "cmd.exe"))
            string = "/c #{string}"
          end
        end

        @cmd_ptr = FFI::MemoryPointer.from_string string
        @app_name_ptr = FFI::MemoryPointer.from_string(@app_name) if @app_name
      end

      def create_environment_pointer
        return unless @environment.kind_of?(Hash) && @environment.any?

        strings = []

        ENV.to_hash.merge(@environment).each do |key, val|
          next if val.nil?

          if key.to_s =~ /=|\0/ || val.to_s.include?("\0")
            raise InvalidEnvironmentVariable, "#{key.inspect} => #{val.inspect}"
          end

          strings << "#{key}=#{val}\0"
        end

        strings << "\0" # terminate the env block
        env_str = strings.join

        @env_ptr = FFI::MemoryPointer.new(:long, env_str.bytesize)
        @env_ptr.put_bytes 0, env_str, 0, env_str.bytesize
      end

      def create_process
        ok = Lib.create_process(
          @app_name_ptr,# application name, i.e. 'cmd.exe' for processing .bat files
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

      # NOTE: A process created with the DETACHED_PROCESS flag cannot inherit
      # its parent's standard I/O devices
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

        @inherit = true
        Lib.set_handle_inheritance @read_pipe, true
        Lib.set_handle_inheritance @write_pipe, false

        startup_info[:hStdInput] = @read_pipe
      end

      def std_stream_handle_for(io)
        handle = Lib.handle_for(io)

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

      def close_handles
        Lib.close_handle process_info[:hProcess]
        Lib.close_handle process_info[:hThread]

        if @duplex
          @stdin = Lib.io_for(Lib.duplicate_handle(@write_pipe), File::WRONLY)
          Lib.close_handle @read_pipe
          Lib.close_handle @write_pipe
        end
      end

      # quote if a string isn't already quoted and it contains whitespace
      #
      # @return [String] quoted with '"'
      def quote_if_necessary(str)
        return str if (str.nil? || str.start_with?('"') || str.start_with?("'"))

        if str.match(/\s/)
          case str
          when /[\"]/
            quote = "'"
          when /[\']/
            quote = '"'
          else
            quote = '"'
          end
          [quote, str, quote].join
        else
          str
        end
      end
    end # ProcessBuilder
  end # Windows
end # ChildProcess
