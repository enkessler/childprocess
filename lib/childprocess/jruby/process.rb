require "java"

module ChildProcess
  module JRuby
    class Process < AbstractProcess

      def exited?
        return true if @exit_code

        assert_started
        @exit_code = @process.exitValue
      rescue java.lang.IllegalThreadStateException
        false
      ensure
        log(:exit_code => @exit_code)
      end

      def stop(timeout = nil)
        assert_started

        @process.destroy
        @process.waitFor # no way to actually use the timeout here..

        @exit_code = @process.exitValue
      end

      private

      def launch_process
        pb = java.lang.ProcessBuilder.new(@args)

        # not sure why this is necessary
        env = pb.environment
        ENV.each { |k,v| env.put(k, v) }

        @process = pb.start

        # Firefox 3.6 on Snow Leopard has a lot output on stderr, which makes
        # the launch act funny if we don't do something to the streams
        # Closing the streams solves the problem for now, but on other platforms
        # we might need to actually read them.

        @process.getErrorStream.close
        @process.getInputStream.close
      end

    end # Process
  end # JRuby
end # ChildProcess
