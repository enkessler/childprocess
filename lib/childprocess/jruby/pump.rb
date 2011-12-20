module ChildProcess
  module JRuby
    class Pump

      def initialize(input, output)
        @input  = input
        @output = output
        @stop   = false
      end

      def stop
        @stop = true
      end

      def run
        Thread.new { pump }

        self
      end

      private

      def pump
        until @stop
          while @input.available > 0 && !@stop
            @output.write @input.read
          end

          @output.flush
          sleep 0.1
        end

        @output.flush
      rescue java.io.IOException => ex
        $stderr.puts ex.message, ex.backtrace if $DEBUG
      end

    end # Pump
  end # JRuby
end # ChildProcess
