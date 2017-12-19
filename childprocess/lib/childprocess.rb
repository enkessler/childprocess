require 'childprocesscore'

module ChildProcess
  class << self
    #
    # Set this to true to enable experimental use of posix_spawn.
    #
    def posix_spawn=(bool)
      @posix_spawn = bool
    end
  end
end
