# frozen_string_literal: true

module ChildProcess
  # Namespace for the Unix-family (Linux, macOS, BSD, Solaris, AIX,
  # Cygwin) process and IO implementations, used whenever
  # {ChildProcess.unix?} is `true`.
  module Unix
  end
end

require_relative 'unix/io'
require_relative 'unix/process'
