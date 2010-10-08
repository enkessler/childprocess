$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'childprocess'
require 'spec'
require 'spec/autorun'
require 'tempfile'

module ChildProcessSpecHelper

  def ruby_process(*args)
    @process = ChildProcess.build("ruby" , *args)
  end

  def sleeping_ruby
    ruby_process("-e", "sleep")
  end

  def ignored(signal)
    code = <<-RUBY
      trap(#{signal.inspect}, "IGNORE")
      sleep
    RUBY

    ruby_process tmp_script(code)
  end

  def exit_with(exit_code)
    ruby_process(tmp_script("exit(#{exit_code})"))
  end

  def tmp_script(code)
    tf = Tempfile.new("childprocess-temp")
    tf << code
    tf.close

    puts code if $DEBUG

    tf.path
  end
end


Spec::Runner.configure do |config|
  config.include(ChildProcessSpecHelper)
  config.after(:each) {
    @process && @process.alive? && @process.stop
  }
end
