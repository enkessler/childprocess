module ChildProcess::Unix::Platform
  SIZEOF = {
     :posix_spawn_file_actions_t => 8,
     :posix_spawnattr_t => 8
  }
end
