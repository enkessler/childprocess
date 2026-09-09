# frozen_string_literal: true

module ChildProcess
  # Base class for all errors raised by ChildProcess.
  class Error < StandardError
  end

  # Raised by {AbstractProcess#poll_for_exit} when the process is still
  # alive after the given timeout.
  class TimeoutError < Error
  end

  # Raised by abstract methods that a concrete subclass is expected to
  # override (e.g. {AbstractProcess#io}, {AbstractIO#stdout=}'s
  # `check_type`) but hasn't.
  #
  # @api private
  class SubclassResponsibility < Error
  end

  # Raised by {ProcessSpawnProcess#launch_process} when
  # {AbstractProcess#environment} contains a key or value that can't be
  # represented in the child's environment (e.g. it contains a NUL byte,
  # or the key contains `=`).
  class InvalidEnvironmentVariable < Error
  end

  # Raised when the underlying `Process.spawn` call fails, e.g. because
  # the executable does not exist or is not executable.
  class LaunchError < Error
  end
end
