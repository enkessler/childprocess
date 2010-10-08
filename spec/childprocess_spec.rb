require File.expand_path('../spec_helper', __FILE__)

describe ChildProcess do

  it "returns self when started" do
    process = sleeping_ruby
    process.start.should == process
  end

end
