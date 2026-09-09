# frozen_string_literal: true

require File.expand_path('spec_helper', __dir__)

describe ChildProcess::AbstractIO do
  let(:io) { described_class.new }

  it "inherits the parent's IO streams" do
    io.inherit!

    expect(io.stdout).to eq $stdout
    expect(io.stderr).to eq $stderr
  end

  it 'raises SubclassResponsibility when asked to check an IO type' do
    expect { io.stdout = $stdout }.to raise_error(ChildProcess::SubclassResponsibility, /check_type/)
  end
end
