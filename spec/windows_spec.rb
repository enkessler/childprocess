require File.expand_path('../spec_helper', __FILE__)
require "pid_behavior"

if ChildProcess.windows?

  describe ChildProcess::Windows::Process do
    it_behaves_like "a platform that provides the child's pid"
  end

  describe ChildProcess::Windows::IO do
    let(:io) { ChildProcess::Windows::IO.new }

    it "raises an ArgumentError if given IO does not respond to :fileno" do
      lambda { io.stdout = nil }.should raise_error(ArgumentError, /must have :fileno or :to_io/)
    end

    it "raises an ArgumentError if the #to_io does not return an IO " do
      fake_io = Object.new
      def fake_io.to_io() StringIO.new end

      lambda { io.stdout = fake_io }.should raise_error(ArgumentError, /must have :fileno or :to_io/)
    end
  end

  describe ChildProcess::Windows::ProcessBuilder do
    describe "batch file handling" do

      before :each do
        @code = <<-DOS
          @echo ARGS: %*"
        DOS
      end

      it "auto quotes spaces in batch file path when args separate" do
        args = ["foo", "bar", "baz"]
        bat = Tempfile.new(["childprocess temp", ".bat"])
        bat << @code
        bat.close
        @process = ChildProcess.build(bat.path, *args)
        out = Tempfile.new("stdout-bat-spec")
        begin
          @process.io.stdout = out
          @process.start
          @process.wait
          out.rewind
          out.read.should match(/ARGS: foo bar baz/)
        ensure
          out.close
        end
      end

      it "requires manual quoting when building process with string" do
        bat = Tempfile.new(["childprocess temp", ".bat"])
        bat << @code
        bat.close
        command_line = "\"#{bat.path}\" non-quoted args"
        @process = ChildProcess.build(command_line)
        out = Tempfile.new("stdout-bat-spec")
        begin
          @process.io.stdout = out
          @process.start
          @process.wait
          out.rewind
          out.read.should match(/ARGS: non-quoted args/)
        ensure
          out.close
        end
      end

      it "doesn't require full path when that bat file is in the current folder" do
        bat = Tempfile.new(["childprocess temp", ".bat"])
        bat << @code
        bat.close
        filename = File.basename(bat.path)
        folder = File.dirname(bat.path)
        command_line = "\"#{filename}\" \'quoted args\'"
        @process = ChildProcess.build(command_line)
        out = Tempfile.new("stdout-bat-spec")
        begin
          @process.io.stdout = out
          path =
          in_path(folder) do
            @process.start
          end
          @process.wait
          out.rewind
          out.read.should match(/ARGS: \'quoted args\'/)
        ensure
          out.close
        end
      end

    end
  end
end
