require File.expand_path('../spec_helper', __FILE__)

describe ChildProcess do

  it "returns self when started" do
    process = sleeping_ruby
    process.start.should == process
    process.should be_started
  end

  it "should return the correct exit code" do
    process = exit_with(123).start
    process.poll_for_exit(1)

    process.should be_exited
    process.exit_code.should == 123
  end

  it "should know if the process crashed" do
    process = exit_with(1).start
    process.poll_for_exit(1)

    process.should be_exited
    process.should be_crashed
  end

  it "should know if the process didn't crash" do
    process = exit_with(0).start
    process.poll_for_exit(1)

    process.should be_exited
    process.should_not be_crashed
  end

  it "should escalate if TERM is ignored" do
    process = ignored('TERM').start
    process.stop
    process.should be_exited
  end

end
