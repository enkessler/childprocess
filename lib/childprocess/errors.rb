module ChildProcess
  class Error < StandardError; end
  class TimeoutError < StandardError; end
  class SubclassResponsibility < StandardError; end
  class InvalidEnvironmentVariableName < StandardError; end
  class LaunchError < StandardError; end

  class MissingPlatformError < StandardError
    def message
      "posix_spawn is not yet supported on #{FFI::Platform::NAME}, falling back to fork/exec\n" +
      "please file a bug at http://github.com/jarib/childprocess/issues"
    end
  end
end