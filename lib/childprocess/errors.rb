module ChildProcess
  class Error < StandardError; end
  class TimeoutError < StandardError; end
  class SubclassResponsibility < StandardError; end
  class InvalidEnvironmentVariableName < StandardError; end
end