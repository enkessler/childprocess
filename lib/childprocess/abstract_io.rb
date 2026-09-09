# frozen_string_literal: true

module ChildProcess
  # Configures the IO streams (stdin/stdout/stderr) of a child process
  # before it is started. Accessed via {AbstractProcess#io}.
  #
  # What counts as a valid IO object is platform-specific (see
  # {Unix::IO#check_type} and {Windows::IO#check_type}), so this class is
  # never instantiated directly.
  class AbstractIO
    # @return [IO, nil] the stream the child's stderr is redirected to, or `nil` if unset
    attr_reader :stderr

    # @return [IO, nil] the stream the child's stdout is redirected to, or `nil` if unset
    attr_reader :stdout

    # @return [IO, nil] the write end of the duplex pipe, once the process has started
    #   with {AbstractProcess#duplex} set to `true`
    attr_reader :stdin

    #
    # Make the child inherit stdout/stderr from the current process.
    #
    # @return [void]

    def inherit!
      @stdout = $stdout
      @stderr = $stderr
    end

    #
    # @param io [IO] where the child's stderr should be redirected to
    # @raise [ArgumentError, TypeError] if `io` is not a valid IO-like object for this platform
    # @return [IO]

    def stderr=(io)
      check_type io
      @stderr = io
    end

    #
    # @param io [IO] where the child's stdout should be redirected to
    # @raise [ArgumentError, TypeError] if `io` is not a valid IO-like object for this platform
    # @return [IO]

    def stdout=(io)
      check_type io
      @stdout = io
    end

    #
    # Sets the read end of the duplex pipe as {#stdin}, once the process
    # has started with {AbstractProcess#duplex} set to `true`.
    #
    # @api private
    #

    def _stdin=(io)
      check_type io
      @stdin = io
    end

    private

    # @raise [ArgumentError, TypeError] always, unless overridden by a subclass
    def check_type(_io)
      raise SubclassResponsibility, 'check_type'
    end
  end
end
