module ChildProcess
  module Windows
    class IO < AbstractIO
      private

      def check_type(io)
        unless io.respond_to?(:fileno)
          raise ArgumentError, "expected #{io.inspect} to respond to :fileno"
        end

        unless io.fileno
          raise ArgumentError, "#{io.inspect}.fileno cannot be nil"
        end
      end

    end # IO
  end # Unix
end # ChildProcess


