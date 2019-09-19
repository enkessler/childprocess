# Based on the example from https://en.wikibooks.org/wiki/Ruby_Programming/RubyGems#How_to_install_different_versions_of_gems_depending_on_which_version_of_ruby_the_installee_is_using
require 'rubygems'
require 'rubygems/command.rb'
require 'rubygems/dependency_installer.rb'

begin
  Gem::Command.build_args = ARGV
rescue NoMethodError # rubocop:disable Lint/HandleExceptions
end

inst = Gem::DependencyInstaller.new
ffi_requirement = Gem::Requirement.new('~> 1.0', '>= 1.0.11')
no_required_ffi = Gem::Specification.none? do |s|
  s.name == 'ffi' && ffi_requirement.satisfied_by?(s.version)
end

begin
  if Gem.win_platform? && no_required_ffi
    inst.install 'ffi', ffi_requirement
  end
rescue # rubocop:disable Lint/RescueWithoutErrorClass
  exit(1)
end

 # create dummy rakefile to indicate success
File.open(File.join(File.dirname(__FILE__), 'Rakefile'), 'w') do |f|
  f.write("task :default\n")
end
