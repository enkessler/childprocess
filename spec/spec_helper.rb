$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))

require 'childprocess'
require 'rspec'
require 'tempfile'
require 'socket'
require 'stringio'

module ChildProcessSpecHelper
  RUBY = defined?(Gem) ? Gem.ruby : 'ruby'

  def ruby_process(*args)
    @process = ChildProcess.build(RUBY , *args)
  end

  def sleeping_ruby
    ruby_process("-e", "sleep")
  end

  def invalid_process
    @process = ChildProcess.build("unlikelytoexist")
  end

  def ignored(signal)
    code = <<-RUBY
      trap(#{signal.inspect}, "IGNORE")
      sleep
    RUBY

    ruby_process tmp_script(code)
  end

  def write_env(path)
    code = <<-RUBY
      File.open(#{path.inspect}, "w") { |f| f << ENV.inspect }
    RUBY

    ruby_process tmp_script(code)
  end

  def write_argv(path, *args)
    code = <<-RUBY
      File.open(#{path.inspect}, "w") { |f| f << ARGV.inspect }
    RUBY

    ruby_process(tmp_script(code), *args)
  end

  def write_pid(path)
    code = <<-RUBY
      File.open(#{path.inspect}, "w") { |f| f << Process.pid }
    RUBY

    ruby_process tmp_script(code)
  end

  def exit_with(exit_code)
    ruby_process(tmp_script("exit(#{exit_code})"))
  end

  def with_env(hash)
    hash.each { |k,v| ENV[k] = v }
    begin
      yield
    ensure
      hash.each_key { |k| ENV[k] = nil }
    end
  end

  def tmp_script(code)
    # use an ivar to avoid GC
    @tf = Tempfile.new("childprocess-temp")
    @tf << code
    @tf.close

    puts code if $DEBUG

    @tf.path
  end

  def within(seconds, &blk)
    end_time   = Time.now + seconds
    ok         = false
    last_error = nil

    until ok || Time.now >= end_time
      begin
        ok = yield
      rescue RSpec::Expectations::ExpectationNotMetError => last_error
      end
    end

    raise last_error unless ok
  end

  def cat
    if ChildProcess.os == :windows
      ruby(<<-CODE)
            STDIN.sync  = true
            STDOUT.sync = true

            puts STDIN.read
          CODE
    else
      ChildProcess.build("cat")
    end
  end

  def echo
    if ChildProcess.os == :windows
      ruby(<<-CODE)
            STDIN.sync  = true
            STDOUT.sync = true

            puts "hello"
          CODE
    else
      ChildProcess.build("echo", "hello")
    end
  end

  def ruby(code)
    ruby_process(tmp_script(code))
  end

  def exit_timeout
    10
  end

  def random_free_port
    server = TCPServer.new('127.0.0.1', 0)
    port   = server.addr[1]
    server.close

    port
  end

  def with_tmpdir(&blk)
    name = "#{Time.now.strftime("%Y%m%d")}-#{$$}-#{rand(0x100000000).to_s(36)}"
    FileUtils.mkdir_p(name)

    begin
      yield File.expand_path(name)
    ensure
      FileUtils.rm_rf name
    end
  end

  def wait_until(timeout = 10, &blk)
    end_time = Time.now + timeout

    until Time.now >= end_time
      return if yield
      sleep 0.05
    end

    raise "timed out"
  end

  def can_bind?(host, port)
    TCPServer.new(host, port).close
    true
  rescue
    false
  end

end # ChildProcessSpecHelper

Thread.abort_on_exception = true

RSpec.configure do |c|
  c.include(ChildProcessSpecHelper)
  c.after(:each) {
    @process && @process.alive? && @process.stop
  }

  if ChildProcess.jruby? && ChildProcess.new("true").instance_of?(ChildProcess::JRuby::Process)
    c.filter_run_excluding :process_builder => false
  end

  if ChildProcess.linux? && ChildProcess.posix_spawn?
    c.filter_run_excluding :posix_spawn_on_linux => false
  end
end
