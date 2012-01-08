module ChildProcess::Unix::Platform
  SIZEOF = {
     :posix_spawn_file_actions_t => 76,
     :posix_spawnattr_t => 80
  }
end
