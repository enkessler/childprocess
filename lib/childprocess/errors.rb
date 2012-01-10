module ChildProcess
  class Error < StandardError; end
  class TimeoutError < StandardError; end
  class SubclassResponsibility < StandardError; end
  class InvalidEnvironmentVariable < StandardError; end
  class LaunchError < StandardError; end

  class MissingPlatformError < StandardError
    def initialize
      platform = ChildProcess.platform_name

      message = "posix_spawn is not yet supported on #{ChildProcess.platform_name} (#{RUBY_PLATFORM}), falling back to default implementation. " +
                "If you believe this is an error, please file a bug at http://github.com/jarib/childprocess/issues"

      super(message)
    end

  end
end