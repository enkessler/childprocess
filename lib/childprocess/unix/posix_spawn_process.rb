require 'ffi'

module ChildProcess
  module Unix
    class PosixSpawnProcess < Process
      private

      def launch_process
        pid_ptr = FFI::MemoryPointer.new(:pid_t)
        actions = Lib::FileActions.new
        attrs   = Lib::Attrs.new
        flags   = 0

        if @io
          if @io.stdout
            actions.add_dup fileno_for(@io.stdout), fileno_for($stdout)
          else
            actions.add_open fileno_for($stdout), "/dev/null", File::WRONLY, 0644
          end

          if @io.stderr
            actions.add_dup fileno_for(@io.stderr), fileno_for($stderr)
          else
            actions.add_open fileno_for($stderr), "/dev/null", File::WRONLY, 0644
          end
        end

        if duplex?
          reader, writer = ::IO.pipe
          actions.add_dup fileno_for(reader), fileno_for($stdin)
          actions.add_close fileno_for(writer)
        end

        if defined? Platform::POSIX_SPAWN_USEVFORK
          flags |= Platform::POSIX_SPAWN_USEVFORK
        end

        attrs.flags = flags

        # wrap in helper classes in order to avoid GC'ed pointers
        argv = Argv.new(@args)
        envp = Envp.new(ENV.to_hash.merge(@environment))

        ret = Lib.posix_spawnp(
          pid_ptr,
          @args.first, # TODO: not sure this matches exec() behaviour
          actions,
          attrs,
          argv,
          envp
        )

        if duplex?
          io._stdin = writer
          reader.close
        end

        actions.free
        attrs.free

        if ret != 0
          raise LaunchError, "#{Lib.strerror(ret)} (#{ret})"
        end

        @pid = pid_ptr.read_int
        ::Process.detach(@pid) if detach?
      end

      if ChildProcess.jruby?
        def fileno_for(obj)
          ChildProcess::JRuby.posix_fileno_for(obj)
        end
      else
        def fileno_for(obj)
          obj.fileno
        end
      end

      class Argv
        def initialize(args)
          @ptrs = args.map do |e|
            if e.include?("\0")
              raise ArgumentError, "argument cannot contain null bytes: #{e.inspect}"
            end

            FFI::MemoryPointer.from_string(e.to_s)
          end

          @ptrs << nil
        end

        def to_ptr
          argv = FFI::MemoryPointer.new(:pointer, @ptrs.size)
          argv.put_array_of_pointer(0, @ptrs)

          argv
        end
      end # Argv

      class Envp
        def initialize(env)
          @ptrs = env.map do |key, val|
            next if val.nil?

            if key =~ /=|\0/ || val.include?("\0")
              raise InvalidEnvironmentVariable, "#{key.inspect} => #{val.inspect}"
            end

            FFI::MemoryPointer.from_string("#{key}=#{val}")
          end.compact

          @ptrs << nil
        end

        def to_ptr
          env = FFI::MemoryPointer.new(:pointer, @ptrs.size)
          env.put_array_of_pointer(0, @ptrs)

          env
        end
      end # Envp

    end
  end
end
