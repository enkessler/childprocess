# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'childprocess/version'

Gem::Specification.new do |s|
  s.name        = 'childprocess'
  s.version     = ChildProcess::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['Jari Bakken', 'Eric Kessler', 'Shane da Silva']
  s.email       = ['morrow748@gmail.com', 'shane@dasilva.io']
  s.homepage    = 'https://github.com/enkessler/childprocess'
  s.summary     = 'A simple and reliable solution for controlling external programs running in the background.'
  s.description = 'This gem aims at being a simple and reliable solution for controlling external programs ' \
                  'running in the background on any Ruby / OS combination.'

  s.license           = 'MIT'
  s.metadata          = {
    'bug_tracker_uri' => 'https://github.com/enkessler/childprocess/issues',
    'changelog_uri' => 'https://github.com/enkessler/childprocess/blob/master/CHANGELOG.md',
    'source_code_uri' => 'https://github.com/enkessler/childprocess/',
    'rubygems_mfa_required' => 'true'
  }

  s.files         = `git ls-files`.split("\n")
  s.require_paths = ['lib']

  s.required_ruby_version = '>= 3.2'

  s.add_dependency 'logger', '~> 1.5'

  s.add_development_dependency 'bundler-audit', '~> 0.9'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rspec', '~> 3.13'
  s.add_development_dependency 'rubocop', '~> 1.88'
  s.add_development_dependency 'rubocop-performance', '~> 1.26'
  s.add_development_dependency 'rubocop-rspec', '~> 3.10'
  s.add_development_dependency 'simplecov', '~> 1.2'
  s.add_development_dependency 'yard', '~> 0.9'
end
