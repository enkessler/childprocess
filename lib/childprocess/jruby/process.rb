require "java"

module ChildProcess
  module JRuby
    class Process < AbstractProcess
      def initialize(args)
        super(args)

        @pumps = []
      end

      def io
        @io ||= JRuby::IO.new
      end

      def exited?
        return true if @exit_code

        assert_started
        @exit_code = @process.exitValue
        stop_pumps

        true
      rescue java.lang.IllegalThreadStateException
        false
      ensure
        log(:exit_code => @exit_code)
      end

      def stop(timeout = nil)
        assert_started

        @process.destroy
        @process.waitFor # no way to actually use the timeout here..

        stop_pumps
        @exit_code = @process.exitValue
      end

      #
      # Block until the process has been terminated.
      #
      # @return [FixNum] The exit status of the process
      #

      def wait
        @process.waitFor

        stop_pumps
        @exit_code = @process.exitValue
      end

      #
      # Only supported in JRuby on a Unix operating system, thanks to limitations
      # in Java's classes
      #
      # @return [Fixnum] the pid of the process after it has started
      # @raise [NotImplementedError] when trying to access pid on non-Unix platform
      #
      def pid
        if @process.getClass.getName != "java.lang.UNIXProcess"
          raise NotImplementedError, "pid is only supported by JRuby child processes on Linux"
        end

        # About the best way we can do this is with a nasty reflection-based impl
        # Thanks to Martijn Courteaux
        # http://stackoverflow.com/questions/2950338/how-can-i-kill-a-linux-process-in-java-with-sigkill-process-destroy-does-sigter/2951193#2951193
        field = @process.getClass.getDeclaredField("pid")
        field.accessible = true
        field.get(@process)
      end

      private

      def launch_process(&blk)
        pb = java.lang.ProcessBuilder.new(@args)

        pb.directory java.io.File.new(Dir.pwd)
        set_env pb.environment

        begin
          @process = pb.start
        rescue java.io.IOException => ex
          raise LaunchError, ex.message
        end

        setup_io
      end

      def setup_io
        if @io
          @pumps << redirect(@process.getErrorStream, @io.stderr)
          @pumps << redirect(@process.getInputStream, @io.stdout)
        else
          @process.getErrorStream.close
          @process.getInputStream.close
        end

        if duplex?
          stdin = @process.getOutputStream.to_io
          stdin.sync = true

          io._stdin = stdin
        else
          @process.getOutputStream.close
        end
      end

      def redirect(input, output)
        if output.nil?
          input.close
          return
        end

        Pump.new(input, output.to_outputstream).run
      end

      def stop_pumps
        @pumps.each { |pump| pump.stop }
      end

      def set_env(env)
        ENV.each { |k,v| env.put(k, v) } # not sure why this is needed
        @environment.each { |k,v| env.put(k.to_s, v.to_s) }
      end

    end # Process
  end # JRuby
end # ChildProcess
