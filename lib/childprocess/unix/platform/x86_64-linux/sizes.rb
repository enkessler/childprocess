module ChildProcess::Unix::Platform
  SIZEOF = {
     :posix_spawn_file_actions_t => 80,
     :posix_spawnattr_t => 80
  }
end
