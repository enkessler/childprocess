module ChildProcess
  class Error < StandardError; end
  class TimeoutError < StandardError; end
  class SubclassResponsibility < StandardError; end
  class InvalidEnvironmentVariableName < StandardError; end
  class LaunchError < StandardError; end

  class MissingPlatformError < StandardError
    def initialize
      platform = defined?(FFI::Platform::NAME) ? FFI::Platform::NAME : RUBY_PLATFORM

      message = "posix_spawn is not yet supported on #{}, falling back to fork() + exec(). " +
                "Please file a bug at http://github.com/jarib/childprocess/issues"

      super(message)
    end

  end
end