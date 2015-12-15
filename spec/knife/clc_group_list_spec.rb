require 'chef/knife/clc_group_list'

describe Chef::Knife::ClcGroupList do
  let(:valid_argv) { %w(--datacenter ca1) }

  it_behaves_like 'a Knife CLC command' do
    let(:argv) { valid_argv }
  end

  include_context 'a Knife command'

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

  before(:each) do
    allow(connection).to receive(:list_groups) { [root_group, child_group] }
  end

  context 'considering command parameters' do
    context 'with valid ones' do
      context 'with tree view' do
        let(:argv) { valid_argv.concat(%w(--view tree)) }

        it { is_expected.to_not raise_error }
      end

      context 'with table view' do
        let(:argv) { valid_argv.concat(%w(--view table)) }

        it { is_expected.to_not raise_error }
      end

      context 'without a view' do
        let(:argv) { valid_argv }

        it { is_expected.to_not raise_error }
      end
    end

    context 'with invalid ones' do
      before(:each) { allow(command).to receive(:exit) }

      subject(:output) do
        run.call
        stderr.string
      end

      context 'meaning invalid view' do
        let(:argv) { valid_argv.concat(%w(--view invalid)) }

        it { is_expected.to match(/either table or a tree/i) }
      end

      context 'meaning missing required ones' do
        let(:argv) { [] }

        it { is_expected.to match(/datacenter id is required/i) }
      end
    end
  end

  let(:argv) { valid_argv }

  context 'considering displayed information' do
    subject(:output) do
      run.call
      stdout.string
    end

    context 'for table view' do
      let(:argv) { valid_argv.concat(%w(--view table)) }

      it { is_expected.to match(/ID/i) }
      it { is_expected.to match(/Name/i) }
      it { is_expected.to match(/Description/i) }
      it { is_expected.to match(/Type/i) }
      it { is_expected.to match(/Status/i) }
      it { is_expected.to match(/Parent/i) }

      it { is_expected.to include(child_group['id']) }
      it { is_expected.to include(child_group['name']) }
      it { is_expected.to include(child_group['description'][0..10]) }
      it { is_expected.to include(child_group['type']) }
      it { is_expected.to include(child_group['status']) }
      it { is_expected.to include(child_group['links'].first['id']) }
    end

    context 'for tree view' do
      let(:argv) { valid_argv.concat(%w(--view tree)) }

      context 'considering fields that are always shown' do
        it 'prints group name and ID' do
          root_node = "#{root_group['name']} (#{root_group['id']})"
          expect(output).to include(root_node)
        end
      end

      context 'considering logical structure' do
        it 'prints root group at the start of the line' do
          expect(output).to match(/^#{root_group['name']}/)
        end

        it 'prints child group right beneath it' do
          child_node = Regexp.quote("`-- #{child_group['name']}")
          expect(output).to match(/^#{child_node}/)
        end
      end
    end

    context 'considering situation when there is no data to display' do
      let(:argv) { valid_argv }

      before(:each) { allow(connection).to receive(:list_groups) { [] } }

      it { is_expected.not_to match(/\w/) }
    end
  end
end
