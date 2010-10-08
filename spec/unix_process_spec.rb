shared_examples_for "unix process" do
  it "handles ECHILD race condition where process dies between timeout and KILL" do
    process = sleeping_ruby

    process.stub!(:fork).and_return('fakepid')
    process.stub!(:send_term)
    process.stub!(:poll_for_exit).and_raise(ChildProcess::TimeoutError)
    process.stub!(:send_kill).and_raise(Errno::ECHILD)

    process.start
    lambda { process.stop }.should_not raise_error

    process.stub(:alive?).and_return(false)
  end

  it "handles ESRCH race condition where process dies between timeout and KILL" do
    process = sleeping_ruby

    process.stub!(:fork).and_return('fakepid')
    process.stub!(:send_term)
    process.stub!(:poll_for_exit).and_raise(ChildProcess::TimeoutError)
    process.stub!(:send_kill).and_raise(Errno::ESRCH)

    process.start
    lambda { process.stop }.should_not raise_error

    process.stub(:alive?).and_return(false)
  end
end