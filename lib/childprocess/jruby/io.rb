module ChildProcess
  module JRuby
    class IO < AbstractIO
      private

      def check_type(io)
        unless io.respond_to?(:to_outputstream)
          raise ArgumentError, "expected #{io.inspect} to respond to :to_outputstream"
        end
      end

    end # IO
  end # Unix
end # ChildProcess


