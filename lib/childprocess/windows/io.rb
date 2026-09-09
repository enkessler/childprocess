# frozen_string_literal: true

module ChildProcess
  module Windows
    # {AbstractIO} implementation used on Windows. Accepts any object with
    # a usable `#fileno`, or one whose `#to_io` returns a real `::IO`.
    class IO < AbstractIO
      private

      # @raise [ArgumentError] if `io` has neither a usable `#fileno` nor a `#to_io` returning an `::IO`
      def check_type(io)
        return if has_fileno?(io)
        return if has_to_io?(io)

        raise ArgumentError, "#{io.inspect}:#{io.class} must have :fileno or :to_io"
      end

      # @return [Boolean] whether `io` responds to `#fileno` with a truthy result
      def has_fileno?(io)
        io.respond_to?(:fileno) && io.fileno
      end

      # @return [Boolean] whether `io.to_io` returns a real `::IO`
      def has_to_io?(io)
        io.respond_to?(:to_io) && io.to_io.is_a?(::IO)
      end
    end
  end
end
