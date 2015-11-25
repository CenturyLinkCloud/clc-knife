require 'chef/knife'
require 'chef/knife/clc_template_list'

describe Chef::Knife::ClcTemplateList do
  subject(:command) { Chef::Knife::ClcTemplateList.new }

  describe '#run' do
    subject(:run) { -> { command.run } }

    let(:connection) { double }

    before(:each) do
      command.config[:clc_datacenter] = 'ca1'
      allow(command).to receive(:connection) { connection }
      allow(command).to receive(:exit)
      allow(connection).to receive(:list_templates) { [] }
    end

    context 'considering command options' do
      context 'with datacenter provided' do
        it { is_expected.not_to raise_error }
      end

      context 'without datacenter' do
        before(:each) { command.config.delete(:clc_datacenter) }

        context 'considering system status' do
          before(:each) do
            allow(command).to receive(:exit).and_call_original
          end

          it { is_expected.to raise_error(SystemExit) }
        end

        context 'considering output' do
          it { is_expected.to output(/knife clc template list/i).to_stdout_from_any_process }
          it { is_expected.to output(/required/i).to_stderr_from_any_process }
        end
      end
    end

    context 'considering displayed information' do
      context 'when there is data available' do
        before(:each) do
          allow(connection).to receive(:list_templates) { [template] }
        end

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

        context 'considering fields that are always shown' do
          it { is_expected.to output(/#{template['name']}/).to_stdout_from_any_process }
          it { is_expected.to output(/#{template['osType']}/).to_stdout_from_any_process }
          it { is_expected.to output(/#{template['storageSizeGB']} GB/).to_stdout_from_any_process }
          it { is_expected.to output(/#{template['capabilities'].first}/).to_stdout_from_any_process }
          it { is_expected.to output(/#{template['description'][0..10]}/).to_stdout_from_any_process }
        end

        context 'considering headers' do
          it { is_expected.to output(/Name/).to_stdout_from_any_process }
          it { is_expected.to output(/OS Type/).to_stdout_from_any_process }
          it { is_expected.to output(/Description/).to_stdout_from_any_process }
          it { is_expected.to output(/Storage/).to_stdout_from_any_process }
          it { is_expected.to output(/Capabilities/).to_stdout_from_any_process }
          it { is_expected.to output(/API Only/).to_stdout_from_any_process }
        end

        context 'considering ignored fields' do
          before(:each) { template['unknownField'] = 'Something' }

          it { is_expected.to_not output(/bin/).to_stdout_from_any_process }
          it { is_expected.to_not output(/unknownField/).to_stdout_from_any_process }
          it { is_expected.to_not output(/Something/).to_stdout_from_any_process }
        end
      end

      context 'when there is no data available' do
        it { is_expected.to_not output(/./).to_stdout_from_any_process }
      end
    end
  end
end
