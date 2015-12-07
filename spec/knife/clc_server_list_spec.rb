require 'chef/knife'
require 'chef/knife/clc_server_list'

describe Chef::Knife::ClcServerList do
  subject(:command) { Chef::Knife::ClcServerList.new }

  describe '#run' do
    subject(:run) { -> { command.run } }

    let(:connection) { double }

    before(:each) do
      allow(command).to receive(:connection) { connection }
      allow(command).to receive(:exit) { raise 'SystemExit' }

      command.config[:clc_datacenter] = 'ca1'
      allow(connection).to receive(:list_datacenters) { [] }
      allow(connection).to receive(:list_servers) { [] }
    end

    context 'considering displayed information' do
      context 'when there is data available' do
        before(:each) do
          allow(connection).to receive(:list_servers) { [server] }
        end

        let(:server) do
          { 'id' => 'ca1altdtest48L', 'name' => 'CA1ALTDTEST48', 'description' => 'none',
            'groupId' => '975a79f94b84452ea1c920325967a33c', 'locationId' => 'CA1',
            'osType' => 'Debian 7 64-bit', 'status' => 'active' }
        end

        context 'considering fields that are always shown' do
          it { is_expected.to output(/#{server['id']}/i).to_stdout_from_any_process }
          it { is_expected.to output(/#{server['name']}/i).to_stdout_from_any_process }
          it { is_expected.to output(/#{server['description']}/i).to_stdout_from_any_process }
          it { is_expected.to output(/#{server['groupId']}/i).to_stdout_from_any_process }
          it { is_expected.to output(/#{server['locationId']}/i).to_stdout_from_any_process }
          it { is_expected.to output(/#{server['osType']}/i).to_stdout_from_any_process }
          it { is_expected.to output(/#{server['status']}/i).to_stdout_from_any_process }
        end

        context 'considering headers' do
          it { is_expected.to output(/ID/).to_stdout_from_any_process }
          it { is_expected.to output(/Name/).to_stdout_from_any_process }
          it { is_expected.to output(/Description/).to_stdout_from_any_process }
          it { is_expected.to output(/Group ID/).to_stdout_from_any_process }
          it { is_expected.to output(/Location ID/).to_stdout_from_any_process }
          it { is_expected.to output(/OS Type/).to_stdout_from_any_process }
          it { is_expected.to output(/Status/i).to_stdout_from_any_process }
        end
      end
    end

    context 'considering command options' do
      context 'with datacenter provided' do
        it { is_expected.not_to raise_error }
      end

      context 'without datacenter' do
        before(:each) { command.config.delete(:clc_datacenter) }

        context 'considering system status' do
          it { is_expected.to raise_error(/SystemExit/) }
        end

        context 'considering output' do
          before(:each) { allow(command).to receive(:exit) }

          it { is_expected.to output(/Datacenter ID is required/i).to_stderr_from_any_process }
        end
      end

      context 'without datacenter but with all option' do
        before(:each) do
          command.config.delete(:clc_datacenter)
          command.config[:clc_all] = true
        end

        it { is_expected.not_to raise_error }
      end
    end
  end
end
