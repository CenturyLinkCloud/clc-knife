require 'chef/knife'
require 'chef/knife/clc_operation_show'

describe Chef::Knife::ClcOperationShow do
  subject(:command) { Chef::Knife::ClcOperationShow.new }

  describe '#execute' do
    subject(:execute) { -> { command.execute } }

    before(:each) do
      allow(command).to receive(:config_file_settings) { {} }
      command.configure_chef
      command.config[:clc_wait] = true
      command.name_args = [operation_id]

      allow(command).to receive(:connection) { connection }
      allow(command.ui).to receive(:info) { |msg| puts msg }
      allow(connection).to receive(:show_operation) { operation }

      allow(connection).to receive(:wait_for) do |&block|
        4.times { block.call }
      end
    end

    let(:connection) { double }
    let(:operation_id) { 'ca1-41967' }
    let(:operation) { { 'status' => 'succeeded' } }

    context 'without waiting' do
      before(:each) do
        command.config.delete(:clc_wait)
      end

      it { is_expected.to output(/Status/).to_stdout_from_any_process }
      it { is_expected.to output(/#{operation['status']}/).to_stdout_from_any_process }
    end

    context 'with waiting' do
      it { is_expected.to output(/waiting for operation/i).to_stdout_from_any_process }
      it { is_expected.to output(/has been completed/).to_stdout_from_any_process }
      it { is_expected.to_not output(/Status/).to_stdout_from_any_process }
    end
  end

  describe '#parse_and_validate_parameters' do
    context 'considering required parameters' do
      subject(:errors) do
        command.parse_and_validate_parameters
        command.errors
      end

      it { is_expected.to include(match(/operation id is required/i)) }
    end
  end
end
