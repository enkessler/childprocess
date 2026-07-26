# frozen_string_literal: true

require File.expand_path('spec_helper', __dir__)

describe ChildProcess::ProcessSpawnProcess do
  # These specs stub out ::Process.spawn entirely, so they build the process
  # directly (rather than via helpers like #sleeping_ruby) to avoid the
  # global spec_helper `after(:each)` hook trying to stop/reap a fake pid
  # once the example's stubs have been torn down.
  let(:process) { ChildProcess.build('ruby', '-e', 'sleep') }

  describe '#exited?' do
    it 'treats Errno::ECHILD from waitpid2 as the process having exited (e.g. a detached process)' do
      allow(Process).to receive(:spawn).and_return('fakepid')
      process.start

      allow(Process).to receive(:waitpid2).and_raise(Errno::ECHILD)

      expect(process.exited?).to be true
    end
  end

  describe '#launch_process' do
    it 'requests a new process group via :new_pgroup when leader on Windows' do
      process.leader = true
      allow(ChildProcess).to receive(:windows?).and_return(true)

      spawn_options = nil
      allow(Process).to receive(:spawn) do |*spawn_args|
        spawn_options = spawn_args.last
        'fakepid'
      end

      process.start

      expect(spawn_options[:new_pgroup]).to be true
    end
  end

  describe '#send_signal' do
    it 'shells out to taskkill when signaling the leader of a process group on Windows' do
      allow(Process).to receive(:spawn).and_return('fakepid')
      process.leader = true
      process.start

      allow(ChildProcess).to receive(:unix?).and_return(false)
      allow(process).to receive(:`).and_return("SUCCESS\n")

      process.send(:send_term)

      expect(process).to have_received(:`).with('taskkill /F /T /PID fakepid')
    end
  end
end
