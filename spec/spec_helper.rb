$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'childprocess'
require 'spec'
require 'spec/autorun'

module ChildProcessSpecHelper
  def sleeping_ruby
    @process = ChildProcess.build("ruby" , "-e", "sleep")
  end
end


Spec::Runner.configure do |config|
  config.include(ChildProcessSpecHelper)
  config.after(:each) {
    @process && @process.alive? && @process.stop
  }
end
