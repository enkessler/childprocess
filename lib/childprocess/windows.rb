require "rbconfig"

begin
  require 'ffi'
rescue LoadError
  raise ChildProcess::MissingFFIError
end

module ChildProcess
  module Windows
    module Lib
      extend FFI::Library

      def self.msvcrt_name
        RbConfig::CONFIG['RUBY_SO_NAME'][/msvc\w+/] || 'ucrtbase'
      end

      ffi_lib "kernel32", msvcrt_name
      ffi_convention :stdcall

    end # Library
  end # Windows
end # ChildProcess

require "childprocess/windows/lib"
require "childprocess/windows/structs"
require "childprocess/windows/handle"
require "childprocess/windows/io"
require "childprocess/windows/process_builder"
require "childprocess/windows/process"
