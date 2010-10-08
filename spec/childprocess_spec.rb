require File.expand_path('../spec_helper', __FILE__)

describe ChildProcess do

  EXIT_TIMEOUT = 10

  it "returns self when started" do
    process = sleeping_ruby

    process.start.should == process
    process.should be_started
  end

  it "knows if the process crashed" do
    process = exit_with(1).start

    within(EXIT_TIMEOUT) {
      process.should be_crashed
    }
  end

  it "knows if the process didn't crash" do
    process = exit_with(0).start
    process.poll_for_exit(EXIT_TIMEOUT)

    process.should_not be_crashed
  end

  it "escalates if TERM is ignored" do
    process = ignored('TERM').start
    process.stop
    process.should be_exited
  end

  it "lets child process inherit the environment of the current process" do
    Tempfile.open("env-spec") do |file|
      with_env('env-spec' => 'yes') do
        process = write_env(file.path).start
        process.poll_for_exit(EXIT_TIMEOUT)
      end

      file.rewind
      child_env = eval(file.read)
      child_env['env-spec'].should == 'yes'
    end
  end

  it "passes arguments to the child" do
    args = ["foo", "bar"]

    Tempfile.open("argv-spec") do |file|
      process = write_argv(file.path, *args).start
      process.poll_for_exit(EXIT_TIMEOUT)

      file.rewind
      file.read.should == args.inspect
    end
  end

  it_should_behave_like "unix process" if ChildProcess.platform == :unix
end
