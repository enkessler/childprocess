require "ffi"

module ChildProcess
  module Windows
    module Lib
      extend FFI::Library

      ffi_lib "kernel32"
      ffi_convention :stdcall
    end
  end
end

require "childprocess/windows/constants"
require "childprocess/windows/structs"
require "childprocess/windows/functions"
require "childprocess/windows/handle"
require "childprocess/windows/api"
require "childprocess/windows/process"