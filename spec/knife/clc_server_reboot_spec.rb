require 'chef/knife'
require 'chef/knife/clc_server_reboot'

describe Chef::Knife::ClcServerReboot do
  subject(:command) { Chef::Knife::ClcServerReboot.new }

  describe '#execute' do
    subject(:execute) { -> { command.execute } }

    before(:each) do
      allow(command).to receive(:config_file_settings) { {} }
      command.configure_chef
      command.config[:clc_wait] = true
      command.name_args = [server_id]

      allow(command).to receive(:connection) { connection }
      allow(command.ui).to receive(:info) { |msg| puts msg }

      allow(connection).to receive(:reboot_server) do
        { 'operation' => reboot_server_link }
      end

      allow(connection).to receive(:wait_for) do |&block|
        4.times { block.call }
      end
    end

    let(:connection) { double }
    let(:server_id) { 'ca1altdtest43' }

    let(:reboot_server_link) do
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

      it { is_expected.to output(/reboot request has been sent/i).to_stdout_from_any_process }
      it { is_expected.to output(/knife clc operation show #{reboot_server_link['id']}/).to_stdout_from_any_process }
    end

    context 'with waiting' do
      it { is_expected.to output(/server has been rebooted/i).to_stdout_from_any_process }
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
    end
  end
end