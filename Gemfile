source "http://rubygems.org"

# Specify your gem's dependencies in child_process.gemspec
gemspec


if RUBY_VERSION =~ /^1\./
  gem 'tins', '< 1.7' # The 'tins' gem requires Ruby 2.x on/after this version
  gem 'json', '< 2.0' # The 'json' gem drops pre-Ruby 2.x support on/after this version
  gem 'term-ansicolor', '< 1.4' # The 'term-ansicolor' gem requires Ruby 2.x on/after this version

  if RbConfig::CONFIG['host_os'].downcase =~ /mswin|msys|mingw32/
    # The 'ffi' gem, for Windows, requires Ruby 2.x on/after this version
    gem 'ffi', '< 1.9.15'
  else
    # Load 'ffi' for testing posix_spawn
    gem 'ffi' if ENV['CHILDPROCESS_POSIX_SPAWN'] == 'true'
  end
else
  # Load 'ffi' for testing posix_spawn, or on windows.
  gem 'ffi' if ENV['CHILDPROCESS_POSIX_SPAWN'] == 'true' || RbConfig::CONFIG['host_os'].downcase =~ /mswin|msys|mingw32/
end
