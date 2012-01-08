require 'ffi'

module ChildProcess
  module Unix
    class PosixSpawnProcess < Process
      def initialize(args)
        super
      end

      private

      def launch_process
        pid_ptr = FFI::MemoryPointer.new(:pid_t)

        actions = Lib::FileActions.new
        attrs   = nil

        if @io
          if @io.stdout
            actions.add_dup @io.stdout.fileno, $stdout.fileno
          else
            actions.add_open $stdout.fileno, "/dev/null", File::WRONLY, 0644
          end

          if @io.stderr
            actions.add_dup @io.stderr.fileno, $stderr.fileno
          else
            actions.add_open $stderr.fileno, "/dev/null", File::WRONLY, 0644
          end
        end

        if duplex?
          reader, writer = ::IO.pipe
          actions.add_dup reader.fileno, $stdin.fileno
          actions.add_close writer.fileno
        end

        ret = Lib.posix_spawnp(
          pid_ptr,
          @args.first, # TODO: pass to /bin/sh if this is the only arg?
          actions,
          attrs,
          argv,
          env
        )

        if duplex?
          io._stdin = writer
          reader.close
        end

        actions.free

        if ret != 0
          raise LaunchError, "#{Lib.strerror(ret)} (#{ret})"
        end

        @pid = pid_ptr.read_int

        ::Process.detach(@pid) if detach?
      end

      def argv
        arg_ptrs = @args.map { |e| FFI::MemoryPointer.from_string(e.to_s) }
        arg_ptrs << nil

        argv = FFI::MemoryPointer.new(:pointer, arg_ptrs.size)
        argv.write_array_of_pointer(arg_ptrs)

        argv
      end

      def env
        env_ptrs = ENV.to_hash.merge(@environment).map do |key, val|
          if key.include?("=")
            raise InvalidEnvironmentVariableName, key
          end

          FFI::MemoryPointer.from_string("#{key}=#{val}")
        end

        env_ptrs << nil

        env = FFI::MemoryPointer.new(:pointer, env_ptrs.size)
        env.write_array_of_pointer(env_ptrs)

        env
      end

    end
  end
end