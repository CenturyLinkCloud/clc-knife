require 'chef'
require 'chef/knife'
require 'chef/knife/clc_server_list'

describe Chef::Knife::ClcServerList do
  subject(:command) { Chef::Knife::ClcServerList.new }

  describe '#execute' do
    subject(:execute) { -> { command.execute } }

    before(:each) do
      Chef.reset!
      Chef::Config.reset
      allow(command).to receive(:config_file_settings) { {} }
      command.configure_chef

      allow(command).to receive(:exit) do |code|
        raise 'SystemExit' unless exit.zero?
      end

      allow(command).to receive(:connection) { connection }

      command.config[:clc_datacenter] = 'ca1'
      allow(connection).to receive(:list_datacenters) { [] }
      allow(connection).to receive(:list_servers) { [] }
    end

    let(:connection) { double }

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

    context 'considering datacenter scoping' do
      context 'when datacenter specified' do
        before(:each) do
          command.config[:clc_datacenter] = 'ca1'
        end

        it { is_expected.not_to raise_error }
      end

      context 'when all opton is specified' do
        before(:each) do
          command.config.delete(:clc_datacenter)
          command.config[:clc_all] = true
          allow(connection).to receive(:list_datacenters) { [datacenter] }
        end

        let(:datacenter) { { 'id' => 'ca1' } }

        it { is_expected.not_to raise_error }
      end
    end
  end

  describe '#parse_and_validate_parameters' do
    context 'considering required parameters' do
      subject(:errors) do
        command.parse_options(argv)
        command.parse_and_validate_parameters
        command.errors
      end

      let(:argv) { [] }

      it { is_expected.to include(match(/datacenter id is required/i)) }

      it 'does not print an error if all option specified' do
        argv << '--all'
        expect(errors).to be_empty
      end
    end
  end
end
