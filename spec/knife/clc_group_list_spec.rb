require 'chef/knife'
require 'chef/knife/clc_group_list'

describe Chef::Knife::ClcGroupList do
  subject(:command) { Chef::Knife::ClcGroupList.new }

  describe '#run' do
    subject(:run) { -> { command.run } }

    let(:connection) { double }

    before(:each) do
      allow(command).to receive(:config_file_settings) { {} }
      allow(command).to receive(:connection) { connection }
      allow(command).to receive(:exit) { raise 'SystemExit' }

      command.configure_chef
      command.config[:clc_datacenter] = 'ca1'

      allow(connection).to receive(:list_groups) { [] }
    end

    context 'considering command options' do
      context 'without view provided' do
        it { is_expected.not_to raise_error }
      end

      context 'with valid view provided' do
        before(:each) { command.config[:clc_view] = 'tree' }

        it { is_expected.not_to raise_error }
      end

      context 'with invalid view provided' do
        before(:each) { command.config[:clc_view] = 'invalid' }

        context 'considering system status' do
          it { is_expected.to raise_error(/SystemExit/) }
        end

        context 'considering output' do
          before(:each) { allow(command).to receive(:exit) }

          it { is_expected.to output(/knife clc group list/i).to_stdout_from_any_process }
          it { is_expected.to output(/either table or a tree/i).to_stderr_from_any_process }
        end
      end

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

          it { is_expected.to output(/knife clc group list/i).to_stdout_from_any_process }
          it { is_expected.to output(/required/i).to_stderr_from_any_process }
        end
      end
    end

    context 'considering displayed information' do
      context 'when there is data available' do
        before(:each) do
          allow(connection).to receive(:list_groups) { [root_group, child_group] }
        end

        let(:root_group) do
          {
            'id' => '5ffda89a8ce6444baa8d28b9d1581e6d',
            'name' => 'CA1 Hardware',
            'description' => 'CA1 Hardware',
            'locationId' => 'CA1',
            'type' => 'default',
            'status' => 'active',
            'serversCount' => 1,
            'customFields' => [],
            'links' => []
          }
        end

        let(:child_group) do
          {
            'id' => '5f69973e31d34bbbb76b0e1542b3a93a',
            'name' => 'Archive',
            'description' => 'Pay only for the storage consumed by the archived server. No compute or licensing costs are incurred.',
            'locationId' => 'CA1',
            'type' => 'archive',
            'status' => 'active',
            'serversCount' => 1,
            'links' => [
              {
                'rel' => 'parentGroup',
                'href' => '/v2/groups/altd/5ffda89a8ce6444baa8d28b9d1581e6d',
                'id' => '5ffda89a8ce6444baa8d28b9d1581e6d'
              }
            ]
          }
        end

        context 'and table view' do
          before(:each) { command.config[:clc_view] = 'table' }

          context 'considering fields that are always shown' do
            it { is_expected.to output(/#{root_group['id']}/).to_stdout_from_any_process }
            it { is_expected.to output(/#{root_group['name']}/).to_stdout_from_any_process }
            it { is_expected.to output(/#{root_group['description'][0..10]}/).to_stdout_from_any_process }
            it { is_expected.to output(/#{root_group['type']}/).to_stdout_from_any_process }
            it { is_expected.to output(/#{root_group['status']}/).to_stdout_from_any_process }
          end

          context 'considering headers' do
            it { is_expected.to output(/ID/).to_stdout_from_any_process }
            it { is_expected.to output(/Name/).to_stdout_from_any_process }
            it { is_expected.to output(/Description/).to_stdout_from_any_process }
            it { is_expected.to output(/Type/).to_stdout_from_any_process }
            it { is_expected.to output(/Status/).to_stdout_from_any_process }
            it { is_expected.to output(/Parent ID/).to_stdout_from_any_process }
          end

          context 'considering ignored fields' do
            before(:each) { root_group['unknownField'] = 'Something' }

            it { is_expected.to_not output(/customFields/).to_stdout_from_any_process }
            it { is_expected.to_not output(/unknownField/).to_stdout_from_any_process }
            it { is_expected.to_not output(/Something/).to_stdout_from_any_process }
          end
        end

        context 'and tree view' do
          before(:each) { command.config[:clc_view] = 'tree' }

          context 'considering fields that are always shown' do
            it 'prints group name and ID' do
              root_node = Regexp.quote("#{root_group['name']} (#{root_group['id']})")
              expect(&subject).to output(/#{root_node}/).to_stdout_from_any_process
            end
          end

          context 'considering logical structure' do
            it 'prints root group at the start of the line' do
              expect(&subject).to output(/^#{root_group['name']}/).to_stdout_from_any_process
            end

            it 'prints child group right beneath it' do
              child_node = Regexp.quote("`-- #{child_group['name']}")
              expect(&subject).to output(/^#{child_node}/).to_stdout_from_any_process
            end
          end
        end
      end

      context 'when there is no data available' do
        it { is_expected.to_not output(/./).to_stdout_from_any_process }
      end
    end
  end
end
