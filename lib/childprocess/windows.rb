# frozen_string_literal: true

require 'rbconfig'

module ChildProcess
  # Namespace for the Windows process and IO implementations, used
  # whenever {ChildProcess.windows?} is `true`.
  module Windows
  end
end

require 'childprocess/windows/io'
require 'childprocess/windows/process'
