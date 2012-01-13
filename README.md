childprocess
============

This gem aims at being a simple and reliable solution for controlling
external programs running in the background on any Ruby / OS combination.

The code originated in the selenium-webdriver gem, but should prove useful as
a standalone library.

[![Build Status](https://secure.travis-ci.org/jarib/childprocess.png)](http://travis-ci.org/jarib/childprocess)

Usage
-----
```ruby
process = ChildProcess.build("ruby", "-e", "sleep")

# inherit stdout/stderr from parent...
process.io.inherit!

# ...or pass an IO
process.io.stdout = Tempfile.new("child-output")

# modify the environment for the child
process.environment["a"] = "b"
process.environment["c"] = nil

# start the process
process.start

# check process status
process.alive?    #=> true
process.exited?   #=> false

# wait indefinitely for process to exit...
process.wait
process.exited?   #=> true

# ...or poll for exit + force quit
begin
  process.poll_for_exit(10)
rescue ChildProcess::TimeoutError
  process.stop # tries increasingly harsher methods to kill the process.
end
```

The object returned from ChildProcess.build will implement ChildProcess::AbstractProcess.

Implementation
--------------

How the process is launched and killed depends on the platform:

* Unix     : fork + exec (or posix_spawn if enabled)
* Windows  : CreateProcess and friends
* JRuby    : java.lang.{Process,ProcessBuilder}

Note on Patches/Pull Requests
-----------------------------

* Fork the project.
* Make your feature addition or bug fix.
* Add tests for it. This is important so I don't break it in a
  future version unintentionally.
* Commit, do not mess with rakefile, version, or history.
  (if you want to have your own version, that is fine but bump version in a commit by itself I can ignore when I pull)
* Send me a pull request. Bonus points for topic branches.

Copyright
---------

Copyright (c) 2010-2012 Jari Bakken. See LICENSE for details.
