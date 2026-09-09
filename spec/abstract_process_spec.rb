# frozen_string_literal: true

require File.expand_path('spec_helper', __dir__)

describe ChildProcess::AbstractProcess do
  let(:process) { described_class.new('foo') }

  describe '#io' do
    it 'raises SubclassResponsibility' do
      expect { process.io }.to raise_error(ChildProcess::SubclassResponsibility, /io/)
    end
  end

  describe '#pid' do
    it 'raises SubclassResponsibility' do
      expect { process.pid }.to raise_error(ChildProcess::SubclassResponsibility, /pid/)
    end
  end

  describe '#stop' do
    it 'raises SubclassResponsibility' do
      expect { process.stop }.to raise_error(ChildProcess::SubclassResponsibility, /stop/)
    end
  end

  describe '#wait' do
    it 'raises SubclassResponsibility' do
      expect { process.wait }.to raise_error(ChildProcess::SubclassResponsibility, /wait/)
    end
  end

  describe '#exited?' do
    it 'raises SubclassResponsibility' do
      expect { process.exited? }.to raise_error(ChildProcess::SubclassResponsibility, /exited\?/)
    end
  end

  describe '#start' do
    it 'raises SubclassResponsibility, since #start calls the unimplemented #launch_process' do
      expect { process.start }.to raise_error(ChildProcess::SubclassResponsibility, /launch_process/)
    end
  end
end
