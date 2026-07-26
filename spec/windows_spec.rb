# frozen_string_literal: true

require File.expand_path('spec_helper', __dir__)
require 'pid_behavior'

# The behavior of ChildProcess::Windows::Process and ChildProcess::Windows::IO
# is plain Ruby with no OS-specific system calls, so most of it can be
# exercised (with ::Process.spawn stubbed out) on any platform, not just
# Windows. Only the shared pid_behavior integration spec actually needs to
# run a real process, so it's gated on ChildProcess.windows?.
describe ChildProcess::Windows::Process do
  it_behaves_like "a platform that provides the child's pid" if ChildProcess.windows?

  let(:process) { described_class.new('ruby', '-e', 'sleep') }

  describe '#io' do
    it 'returns a memoized Windows::IO' do
      expect(process.io).to be_a(ChildProcess::Windows::IO)
      expect(process.io).to equal(process.io)
    end
  end

  describe '#stop' do
    it 'sends KILL and waits for the process to exit' do
      allow(Process).to receive(:spawn).and_return('fakepid')
      process.start

      allow(process).to receive(:send_kill)
      allow(process).to receive(:poll_for_exit).and_return(0)

      expect(process.stop).to eq(0)
      expect(process).to have_received(:send_kill)
    end

    it 'falls back to #wait if polling for exit times out after KILL' do
      allow(Process).to receive(:spawn).and_return('fakepid')
      process.start

      allow(process).to receive(:send_kill)
      allow(process).to receive(:poll_for_exit).and_raise(ChildProcess::TimeoutError)
      allow(process).to receive(:wait).and_return(1)

      expect(process.stop).to eq(1)
    end

    it 'handles ECHILD race condition where process dies between timeout and KILL' do
      allow(Process).to receive(:spawn).and_return('fakepid')
      process.start

      allow(process).to receive(:send_kill).and_raise(Errno::ECHILD.new)

      expect { process.stop }.not_to raise_error
    end

    it 'handles ESRCH race condition where process dies between timeout and KILL' do
      allow(Process).to receive(:spawn).and_return('fakepid')
      process.start

      allow(process).to receive(:send_kill).and_raise(Errno::ESRCH.new)

      expect { process.stop }.not_to raise_error
    end
  end

  describe ChildProcess::Windows::IO do
    let(:io) { described_class.new }

    it 'raises an ArgumentError if given IO does not respond to :fileno' do
      expect { io.stdout = nil }.to raise_error(ArgumentError, /must have :fileno or :to_io/)
    end

    it 'raises an ArgumentError if the #to_io does not return an IO' do
      fake_io = Object.new
      def fake_io.to_io = StringIO.new

      expect { io.stdout = fake_io }.to raise_error(ArgumentError, /must have :fileno or :to_io/)
    end

    it 'accepts an object that responds to :fileno' do
      fake_io = Object.new
      def fake_io.fileno = 5

      expect { io.stdout = fake_io }.not_to raise_error
    end

    it "accepts an object that doesn't respond to :fileno but whose #to_io returns an IO" do
      fake_io = Object.new
      def fake_io.to_io = $stdout

      expect { io.stdout = fake_io }.not_to raise_error
    end
  end
end
