class Java::SunNioCh::FileChannelImpl
  field_reader :fd
end

class Java::JavaIo::FileDescriptor
  field_reader :fd
end


module ChildProcess
  module JRuby
    module NativeFileDescriptor
      def fileno_for(obj)
        channel = ::JRuby.reference(obj).channel
        begin
          channel.getFDVal
        rescue NoMethodError
          fileno = channel.fd
          if fileno.kind_of?(Java::JavaIo::FileDescriptor)
            fileno = fileno.fd
          end

          fileno
        end
      rescue
        obj.fileno
      end
    end
  end
end

