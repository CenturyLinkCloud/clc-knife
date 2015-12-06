require 'chef/knife'
require 'chef/knife/clc_ip_delete'

describe Chef::Knife::ClcIpDelete do
  subject(:command) { Chef::Knife::ClcIpDelete.new }

  describe '#execute' do
    subject(:execute) { -> { command.execute } }

    before(:each) do
      allow(command).to receive(:config_file_settings) { {} }

      allow(command).to receive(:exit) do |code|
        raise 'SystemExit' unless exit.zero?
      end

      command.configure_chef
      command.config[:clc_wait] = true
      command.config[:clc_server] = server_id
      command.name_args = [ip_string]

      allow(command).to receive(:connection) { connection }
      allow(command.ui).to receive(:info) { |msg| puts msg }

      allow(connection).to receive(:delete_ip_address) do
        { 'operation' => ip_removal_link }
      end

      allow(connection).to receive(:wait_for) do |&block|
        4.times { block.call }
      end
    end

    let(:connection) { double }
    let(:server_id) { 'ca1altdtest43' }
    let(:ip_string) { '68.44.12.101' }

    let(:ip_removal_link) do
      {
        'rel' => 'status',
        'href' => '/v2/operations/altd/status/ca1-41967',
        'id' => 'ca1-41967'
      }
    end

    context 'without waiting' do
      before(:each) do
        command.config.delete(:clc_wait)
      end

      it { is_expected.to output(/deletion request has been sent/i).to_stdout_from_any_process }
      it { is_expected.to output(/knife clc operation show #{ip_removal_link['id']}/).to_stdout_from_any_process }
    end

    context 'with waiting' do
      it { is_expected.to output(/ip address has been deleted/i).to_stdout_from_any_process }
      it { is_expected.to_not output(/knife clc/).to_stdout_from_any_process }
    end
  end

  describe '#parse_and_validate_parameters' do
    context 'considering required parameters' do
      subject(:errors) do
        command.parse_and_validate_parameters
        command.errors
      end

      it { is_expected.to include(match(/server id is required/i)) }
      it { is_expected.to include(match(/ip string is required/i)) }
    end
  end
end
