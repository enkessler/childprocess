require File.expand_path('../spec_helper', __FILE__)

describe ChildProcess do
 it "can redirect stdout, stderr" do
    process = ruby(<<-CODE)
      [STDOUT, STDERR].each_with_index do |io, idx|
        io.sync = true
        io.puts idx
      end

      sleep 0.2
    CODE

    out = Tempfile.new("stdout-spec")
    err = Tempfile.new("stderr-spec")

    begin
      process.io.stdout = out
      process.io.stderr = err

      process.start
      process.io.stdin.should be_nil
      process.wait

      out.rewind
      err.rewind

      out.read.should == "0\n"
      err.read.should == "1\n"
    ensure
      out.close
      err.close
    end
  end

  it "can redirect stdout only" do
    process = ruby(<<-CODE)
      [STDOUT, STDERR].each_with_index do |io, idx|
        io.sync = true
        io.puts idx
      end

      sleep 0.2
    CODE

    out = Tempfile.new("stdout-spec")

    begin
      process.io.stdout = out

      process.start
      process.wait

      out.rewind

      out.read.should == "0\n"
    ensure
      out.close
    end
  end

  it "can write to stdin if duplex = true" do
    process = cat

    out = Tempfile.new("duplex")
    out.sync = true

    begin
      process.io.stdout = out
      process.io.stderr = out
      process.duplex = true

      process.start
      process.io.stdin.puts "hello world"
      process.io.stdin.close

      process.poll_for_exit(EXIT_TIMEOUT)

      out.rewind
      out.read.should == "hello world\n"
    ensure
      out.close
    end
  end

  it "works with pipes" do
    process = ruby(<<-CODE)
      STDOUT.puts "stdout"
      STDERR.puts "stderr"
    CODE

    stdout, stdout_w = IO.pipe
    stderr, stderr_w = IO.pipe

    process.io.stdout = stdout_w
    process.io.stderr = stderr_w

    process.duplex = true

    process.start
    process.wait

    stdout_w.close
    stderr_w.close

    stdout.read.should == "stdout\n"
    stderr.read.should == "stderr\n"
  end

  it "can set close-on-exec when IO is inherited" do
    server = TCPServer.new("localhost", 4433)
    ChildProcess.close_on_exec server

    process = sleeping_ruby
    process.io.inherit!

    process.start
    sleep 0.5 # give the forked process a chance to exec() (which closes the fd)

    server.close
    lambda { TCPServer.new("localhost", 4433).close }.should_not raise_error
  end
end
