require 'chef/knife/clc_group_create'

describe Chef::Knife::ClcGroupCreate do
  let(:valid_argv) do
    %w(
      --name test
      --description descr
      --parent 975a79f94b84452ea1c920325967a33c
      --custom-field FIELD=VALUE
    )
  end

  it_behaves_like 'a Knife CLC command' do
    let(:argv) { valid_argv }
  end

  include_context 'a Knife command'

  let(:group) do
    {
      'id' => '35a35c7405d4477da5a2007c3f3cd415',
      'name' => 'test',
      'description' => 'descr',
      'locationId' => 'CA1',
      'type' => 'default',
      'status' => 'active',
      'groups' => [],
      'links' => [
        {
          'rel' => 'parentGroup',
          'href' => '/v2/groups/altd/975a79f94b84452ea1c920325967a33c',
          'id' => '975a79f94b84452ea1c920325967a33c'
        }
      ]
    }
  end

  before(:each) do
    allow(connection).to receive(:create_group) { group }
  end

  context 'considering displayed information' do

  let(:argv) { valid_argv }
    subject(:output) do
      run.call
      stdout.string
    end

    it { is_expected.to match(/Name/i) }
    it { is_expected.to match(/ID/i) }
    it { is_expected.to match(/Location/i) }
    it { is_expected.to match(/Description/i) }
    it { is_expected.to match(/Type/i) }
    it { is_expected.to match(/Status/i) }
    it { is_expected.to match(/Parent/i) }

    it { is_expected.to include(group['name']) }
    it { is_expected.to include(group['id']) }
    it { is_expected.to include(group['locationId']) }
    it { is_expected.to include(group['description']) }
    it { is_expected.to include(group['type']) }
    it { is_expected.to include(group['status']) }
    it { is_expected.to include(group['links'].first['id']) }
  end

  context 'considering command parameters' do
    context 'when they are valid' do
      let(:argv) { valid_argv }

      it 'passes them correctly' do
        expected_params = {
          'name' => 'test',
          'description' => 'descr',
          'parentGroupId' => '975a79f94b84452ea1c920325967a33c',
          'customFields' => [{ 'id' => 'FIELD', 'value' => 'VALUE' }]
        }

        expect(connection).to receive(:create_group).with(hash_including(expected_params))

        run.call
      end
    end

    context 'when they are invalid' do
      before(:each) do
        allow(command).to receive(:exit)
        run.call
      end

      subject(:output) { stderr.string }

      context 'meaning some of them malformed' do
        let(:argv) do
          %w(
            --custom-field FIELDVALUE
          )
        end

        it { is_expected.to include('FIELDVALUE') }
      end

      context 'meaning some of required ones are missing' do
        let(:argv) { [] }

        it { is_expected.to match(/name is required/i) }
        it { is_expected.to match(/parent group id is required/i) }
      end
    end
  end
end
