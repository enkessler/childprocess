require 'childprocess/abstract_process'
require 'childprocess/errors'

module ChildProcess
  autoload :Unix,     'childprocess/unix'
  autoload :Windows,  'childprocess/windows'
  autoload :JRuby,    'childprocess/jruby'
  autoload :IronRuby, 'childprocess/ironruby'

  def self.build(*args)
    case platform
    when :jruby
      JRuby::Process.new(args)
    when :ironruby
      IronRuby::Process.new(args)
    when :windows
      Windows::Process.new(args)
    else
      Unix::Process.new(args)
    end
  end

  def self.platform
    if RUBY_PLATFORM == "java"
      :jruby
    elsif defined?(RUBY_ENGINE) && RUBY_ENGINE == "ironruby"
      :ironruby
    elsif RUBY_PLATFORM =~ /mswin|msys|mingw32/
      :windows
    end
  end

end