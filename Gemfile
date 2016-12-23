source "http://rubygems.org"

# Specify your gem's dependencies in child_process.gemspec
gemspec


if RUBY_VERSION =~ /^1\./
  gem 'tins', '< 1.7' # The 'tins' gem requires Ruby 2.x on/after this version
  gem 'json', '< 2.0' # The 'json' gem drops pre-Ruby 2.x support on/after this version
  gem 'term-ansicolor', '< 1.4' # The 'term-ansicolor' gem requires Ruby 2.x on/after this version
end
