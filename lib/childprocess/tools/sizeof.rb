require 'ffi'
require 'fileutils'

module ChildProcess
  module Tools
    class SizeOf
      EXE_NAME = "childprocess-sizeof-generator"
      TMP_PROGRAM = "childprocess-sizeof-generator.c"

      def self.generate
        new.generate
      end

      def initialize
        @cc = ENV['CC'] || 'gcc'
        @out = File.expand_path("../../unix/platform/#{FFI::Platform::NAME}/sizes.rb", __FILE__)
        @sizeof = {}
      end

      def generate
        fetch_size 'posix_spawn_file_actions_t', "spawn.h"
        fetch_size 'posix_spawnattr_t', "spawn.h"

        write
      end

      def write
        FileUtils.mkdir_p(File.dirname(@out))
        File.open(@out, 'w') do |io|
          io.puts result
        end

        puts "wrote #{@out}"
      end

      def fetch_size(type_name, includes = nil)
        src = Array(includes).map { |include| "#include <#{include}>" }.join("\n")
        src += <<-EOF

#include <stdio.h>
#include <stddef.h>
int main() {
  printf("%d", (unsigned int)sizeof(#{type_name}));
  return 0;
}
        EOF

        File.open(TMP_PROGRAM, 'w') do |file|
          file << src
        end

        cmd = "#{@cc} #{TMP_PROGRAM} -o #{EXE_NAME}"
        system cmd
        unless $?.success?
          raise "failed to compile program: #{cmd.inspect}\n#{src}"
        end

        output = `./#{EXE_NAME} 2>&1`

        unless $?.success?
          raise "failed to run program: #{cmd.inspect}\n#{output}"
        end

        if output.to_i < 1
          raise "sizeof(#{type_name}) == #{output.to_i} (output=#{output})"
        end

        @sizeof[type_name] = output.to_i
      ensure
        File.delete TMP_PROGRAM if File.exist?(TMP_PROGRAM)
        File.delete EXE_NAME if File.exist?(EXE_NAME)
      end

      def result
        if @sizeof.empty?
          raise "no sizes collected, nothing to do"
        end

        out =  ['module ChildProcess::Unix::Platform']
        out << '  SIZEOF = {'
        @sizeof.each_with_index do |(type, size), idx|
          out << "     :#{type} => #{size}#{',' unless idx == @sizeof.size - 1}"
        end

        out << '  }'
        out << 'end'

        out.join "\n"
      end

    end
  end
end