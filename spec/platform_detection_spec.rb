# frozen_string_literal: true

require File.expand_path('spec_helper', __dir__)

# Q: Should platform detection concern be extracted from ChildProcess?
describe ChildProcess do
  describe '.arch' do
    subject { described_class.arch }

    before { described_class.instance_variable_set(:@arch, nil) }

    after { described_class.instance_variable_set(:@arch, nil) }

    shared_examples 'expected_arch_for_host_cpu' do |host_cpu, expected_arch|
      context "when host_cpu is '#{host_cpu}'" do
        before do
          allow(RbConfig::CONFIG)
            .to receive(:[])
            .with('host_cpu')
            .and_return(host_cpu)
        end

        it { is_expected.to eq expected_arch }
      end
    end

    # Normal cases: not macosx - depends only on host_cpu
    context "when os is *not* 'macosx'" do
      before do
        allow(described_class).to receive(:os).and_return(:not_macosx)
      end

      [
        { host_cpu: 'i386',    expected_arch: 'i386'    },
        { host_cpu: 'i486',    expected_arch: 'i386'    },
        { host_cpu: 'i586',    expected_arch: 'i386'    },
        { host_cpu: 'i686',    expected_arch: 'i386'    },
        { host_cpu: 'amd64',   expected_arch: 'x86_64'  },
        { host_cpu: 'x86_64',  expected_arch: 'x86_64'  },
        { host_cpu: 'ppc',     expected_arch: 'powerpc' },
        { host_cpu: 'powerpc', expected_arch: 'powerpc' },
        { host_cpu: 'unknown', expected_arch: 'unknown' }
      ].each do |args|
        include_context 'expected_arch_for_host_cpu', args.values
      end
    end

    # Special cases: macosx - when host_cpu is i686, have to re-check
    context "when os is 'macosx'" do
      before do
        allow(described_class).to receive(:os).and_return(:macosx)
      end

      context "when host_cpu is 'i686'" do
        shared_context 'when checking arch on macosx i686' do |sixty_four_bit, expected_arch|
          context "when Ruby is #{sixty_four_bit ? 64 : 32}-bit" do
            before do
              allow(described_class)
                .to receive(:is_64_bit?)
                .and_return(sixty_four_bit)
            end

            include_context 'expected_arch_for_host_cpu', 'i686', expected_arch
          end
        end

        [
          { sixty_four_bit: true,  expected_arch: 'x86_64' },
          { sixty_four_bit: false, expected_arch: 'i386'   }
        ].each do |args|
          include_context 'when checking arch on macosx i686', args.values
        end
      end

      [
        { host_cpu: 'amd64',   expected_arch: 'x86_64'  },
        { host_cpu: 'x86_64',  expected_arch: 'x86_64'  },
        { host_cpu: 'ppc',     expected_arch: 'powerpc' },
        { host_cpu: 'powerpc', expected_arch: 'powerpc' },
        { host_cpu: 'unknown', expected_arch: 'unknown' }
      ].each do |args|
        include_context 'expected_arch_for_host_cpu', args.values
      end
    end
  end
end
