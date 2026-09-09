# frozen_string_literal: true

module ChildProcess
  module Unix
    # {AbstractIO} implementation used on Unix-family platforms. Accepts
    # any object that responds to `#to_io` and whose `#to_io` returns a
    # real `::IO`.
    class IO < AbstractIO
      private

      # @raise [ArgumentError] if `io` doesn't respond to `#to_io`
      # @raise [TypeError] if `io.to_io` doesn't return an `::IO`
      def check_type(io)
        raise ArgumentError, "expected #{io.inspect} to respond to :to_io" unless io.respond_to? :to_io

        result = io.to_io
        return if result.is_a?(::IO)

        raise TypeError, "expected IO, got #{result.inspect}:#{result.class}"
      end
    end
  end
end
