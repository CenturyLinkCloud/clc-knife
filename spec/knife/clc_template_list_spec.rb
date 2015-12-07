require 'chef/knife/clc_template_list'

describe Chef::Knife::ClcTemplateList do
  let(:valid_args) { %w(--datacenter ca1) }

  it_behaves_like 'a Knife CLC command' do
    let(:argv) { valid_args }
  end

  include_context 'a Knife command'

  let(:template) do
    {
      'name' => 'BOSH-OPENSTACK-CLC-UBUNTU-TRUSTY-GO_AGENT_2922',
      'osType' => 'ubuntu14_64Bit',
      'description' => 'BOSH CLC Stemcell 2922',
      'storageSizeGB' => 143,
      'capabilities' => ['cpuAutoscale'],
      'reservedDrivePaths' => ['bin'],
      'apiOnly' => true
    }
  end

  let(:datacenter) { { 'id' => 'ca1' } }

  before(:each) do
    allow(connection).to receive(:list_templates) { [template] }
    allow(connection).to receive(:list_datacenters) { [datacenter] }
  end

  context 'considering displayed information' do
    let(:argv) { valid_args }

    subject(:output) do
      run.call
      stdout.string
    end

    context 'considering fields that are always shown' do
      it { is_expected.to include(template['name']) }
      it { is_expected.to include(template['osType']) }
      it { is_expected.to include("#{template['storageSizeGB']} GB") }
      it { is_expected.to include(template['capabilities'].first) }
      it { is_expected.to include(template['description'][0..10]) }

      it { is_expected.to match(/Name/i) }
      it { is_expected.to match(/OS Type/i) }
      it { is_expected.to match(/Description/i) }
      it { is_expected.to match(/Storage/i) }
      it { is_expected.to match(/Capabilities/i) }
      it { is_expected.to match(/API Only/i) }
    end

    context 'considering ignored fields' do
      before(:each) { template['unknownField'] = 'Something' }

      it { is_expected.to_not match(/bin/) }
      it { is_expected.to_not match(/unknownField/) }
      it { is_expected.to_not match(/Something/) }
    end

    context 'considering situation when there is no data available' do
      before(:each) { allow(connection).to receive(:list_templates) { [] } }

      it { is_expected.not_to match(/\w/) }
    end
  end

  context 'considering command parameters' do
    context 'when they are valid' do
      context 'meaning datacenter is specified' do
        let(:argv) { valid_args }

        it 'passes them correctly' do
          expect(connection).to receive(:list_templates).
            with('ca1').
            and_return([template])

          run.call
        end
      end

      context 'meaning all option is specified' do
        let(:argv) { %w(--all) }

        it 'passes them correctly' do
          expect(connection).to receive(:list_templates).
            with('ca1').
            and_return([template])

          run.call
        end
      end
    end

    context 'when they are invalid' do
      context 'meaning that required ones are missing' do
        let(:argv) { [] }

        before(:each) do
          allow(command).to receive(:exit)
          run.call
        end

        subject(:output) { stderr.string }

        it { is_expected.to match(/datacenter id is required/i) }
      end
    end
  end
end
