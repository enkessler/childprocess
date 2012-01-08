module ChildProcess
  module Unix
    module Lib
      extend FFI::Library

      ffi_lib FFI::Library::LIBC

      attach_function :strerror, [:int], :string

      # int posix_spawnp(
      #   pid_t *restrict pid,
      #   const char *restrict file,
      #   const posix_spawn_file_actions_t *file_actions,
      #   const posix_spawnattr_t *restrict attrp,
      #   char *const argv[restrict],
      #   char *const envp[restrict]
      # );

      attach_function :posix_spawnp, [
        :pointer,
        :string,
        :pointer,
        :pointer,
        :pointer,
        :pointer
      ], :int

      # int posix_spawn_file_actions_init(posix_spawn_file_actions_t *file_actions);
      attach_function :posix_spawn_file_actions_init, [:pointer], :int

      # int posix_spawn_file_actions_destroy(posix_spawn_file_actions_t *file_actions);
      attach_function :posix_spawn_file_actions_destroy, [:pointer], :int

      # int posix_spawn_file_actions_addclose(posix_spawn_file_actions_t *file_actions, int filedes);
      attach_function :posix_spawn_file_actions_addclose, [:pointer, :int], :int

      # int posix_spawn_file_actions_addopen(
      #   posix_spawn_file_actions_t *restrict file_actions,
      #   int filedes,
      #   const char *restrict path,
      #   int oflag,
      #   mode_t mode
      # );
      attach_function :posix_spawn_file_actions_addopen, [:pointer, :int, :string, :int, :mode_t], :int

      # int posix_spawn_file_actions_adddup2(
      #   posix_spawn_file_actions_t *file_actions,
      #   int filedes,
      #   int newfiledes
      # );
      attach_function :posix_spawn_file_actions_adddup2, [:pointer, :int, :int], :int

      # int posix_spawnattr_init(posix_spawnattr_t *attr);
      attach_function :posix_spawnattr_init, [:pointer], :int

      # int posix_spawnattr_destroy(posix_spawnattr_t *attr);
      attach_function :posix_spawnattr_destroy, [:pointer], :int

      # int posix_spawnattr_setflags(posix_spawnattr_t *attr, short flags);
      attach_function :posix_spawnattr_setflags, [:pointer, :short], :int

      # int posix_spawnattr_getflags(const posix_spawnattr_t *restrict attr, short *restrict flags);
      attach_function :posix_spawnattr_getflags, [:pointer, :pointer], :int

      # int posix_spawnattr_setpgroup(posix_spawnattr_t *attr, pid_t pgroup);
      attach_function :posix_spawnattr_setpgroup, [:pointer, :pid_t], :int

      # int posix_spawnattr_getpgroup(const posix_spawnattr_t *restrict attr, pid_t *restrict pgroup);
      attach_function :posix_spawnattr_getpgroup, [:pointer, :pointer], :int

      # int posix_spawnattr_setsigdefault(posix_spawnattr_t *restrict attr, const sigset_t *restrict sigdefault);
      attach_function :posix_spawnattr_setsigdefault, [:pointer, :pointer], :int

      # int posix_spawnattr_getsigdefault(const posix_spawnattr_t *restrict attr, sigset_t *restrict sigdefault);
      attach_function :posix_spawnattr_getsigdefault, [:pointer, :pointer], :int

      # int posix_spawnattr_setsigmask(posix_spawnattr_t *restrict attr, const sigset_t *restrict sigmask);
      attach_function :posix_spawnattr_setsigmask, [:pointer, :pointer], :int

      # int posix_spawnattr_getsigmask(const posix_spawnattr_t *restrict attr, sigset_t *restrict sigmask);
      attach_function :posix_spawnattr_getsigmask, [:pointer, :pointer], :int

      def self.check(errno)
        if errno != 0
          raise Error, Lib.strerror(errno)
        end
      end

      class FileActions
        def initialize
          @data = FFI::MemoryPointer.new(1, Platform::SIZEOF.fetch(:posix_spawn_file_actions_t), false)
          Lib.check Lib.posix_spawn_file_actions_init(@data)
        end

        def add_close(fileno)
          Lib.check Lib.posix_spawn_file_actions_addclose(
            @data,
            fileno
          )
        end

        def add_open(fileno, path, oflag, mode)
          Lib.check Lib.posix_spawn_file_actions_addopen(
            @data,
            fileno,
            path,
            oflag,
            mode
          )
        end

        def add_dup(fileno, new_fileno)
          Lib.check Lib.posix_spawn_file_actions_adddup2(
            @data,
            fileno,
            new_fileno
          )
        end

        def free
          Lib.check Lib.posix_spawn_file_actions_destroy(@data)
          @data = nil
        end

        def to_ptr
          @data
        end
      end # FileActions

      class Attrs
        def initialize
          @data = FFI::MemoryPointer.new(1, Platform::SIZEOF.fetch(:posix_spawnattr_t), false)
          Lib.check Lib.posix_spawnattr_init(@data)
        end

        def free
          Lib.check Lib.posix_spawnattr_destroy(@data)
          @data = nil
        end

        def to_ptr
          @data
        end
      end # Attrs

    end
  end
end