require 'chef'
require 'chef/knife'
require 'chef/knife/clc_group_create'

describe Chef::Knife::ClcGroupCreate do
  subject(:command) { Chef::Knife::ClcGroupCreate.new }

  before(:each) do
    Chef.reset!
    Chef::Config.reset
    allow(command).to receive(:config_file_settings) { {} }
    command.configure_chef

    allow(command).to receive(:exit) do |code|
      raise 'SystemExit' unless exit.zero?
    end
  end

  describe '#execute' do
    subject(:execute) { -> { command.execute } }
    let(:connection) { double }

    before(:each) do
      allow(command).to receive(:connection) { connection }
      allow(connection).to receive(:create_group) { {} }
    end

    let(:group) do
      {
        'name' => 'group name',
        'description' => 'group description',
        'parentGroupId' => '975a79f94b84452ea1c920325967a33c',
        'links' => [
          { 'rel' => 'parentGroup', 'id' => '975a79f94b84452ea1c920325967a33c' }
        ]
      }
    end

    context 'considering displayed information' do
      before(:each) do
        allow(connection).to receive(:create_group) { group }
      end

      context 'considering fields that are always shown' do
        it { is_expected.to output(/Name/i).to_stdout_from_any_process }
        it { is_expected.to output(/ID/i).to_stdout_from_any_process }
        it { is_expected.to output(/Location/i).to_stdout_from_any_process }
        it { is_expected.to output(/Description/i).to_stdout_from_any_process }
        it { is_expected.to output(/Type/i).to_stdout_from_any_process }
        it { is_expected.to output(/Status/i).to_stdout_from_any_process }
        it { is_expected.to output(/Parent/i).to_stdout_from_any_process }

        it { is_expected.to output(/#{group['name']}/i).to_stdout_from_any_process }
        it { is_expected.to output(/#{group['description']}/i).to_stdout_from_any_process }
        it { is_expected.to output(/#{group['parentGroupId']}/i).to_stdout_from_any_process }
      end
    end

    context 'considering complex parameters' do
      subject(:config) do
        command.parse_options(argv)
        command.parse_and_validate_parameters
        command.config
      end

      let(:argv) do
        %w(
            --name test name
            --parent 975a79f94b84452ea1c920325967a33c
            --custom-field FIELD=VALUE
          )
      end

      it { is_expected.to include(:clc_custom_fields => [{ 'id' => 'FIELD', 'value' => 'VALUE' }]) }

      describe 'when they are malformed' do
        subject(:errors) do
          command.parse_options(argv)
          command.parse_and_validate_parameters
          command.errors
        end

        let(:argv) do
          %w(
              --name test name
              --parent 975a79f94b84452ea1c920325967a33c
              --custom-field FIELDVALUE
            )
        end

        it { is_expected.to include(/FIELDVALUE/) }
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

      it { is_expected.to include(match(/name is required/i)) }
      it { is_expected.to include(match(/parent group id is required/i)) }
    end
  end
end
