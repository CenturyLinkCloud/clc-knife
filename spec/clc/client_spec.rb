describe Clc::Client do
  subject(:client) { Clc::Client.new }

  describe '#list_servers' do
    context 'with cloud success', with_vcr('client/list_servers/success') do
      it 'returns an Array' do
        expect(client.list_servers('ca1')).to be_an(Array)
      end
    end

    context 'with cloud failure', with_vcr('client/list_servers/failure') do
      it 'raises an error' do
        expect { client.list_servers('not-real') }.to raise_error(Clc::CloudExceptions::Error)
      end
    end
  end

  describe '#create_server' do
    let(:params) do
      {
        'name' => 'req',
        'groupId' => '975a79f94b84452ea1c920325967a33c',
        'sourceServerId' => 'CENTOS-6-64-TEMPLATE',
        'cpu' => 1,
        'memoryGB' => 1,
        'type' => 'standard'
      }
    end

    context 'with valid params', with_vcr('client/create_server/valid', :pooling) do
      let(:server) { client.create_server(params) }

      it 'returns a Hash' do
        expect(server).to be_a(Hash)
      end

      it 'passes specified name to the cloud' do
        expect(server['name']).to include(params['name'].upcase)
      end

      it 'places server in specified group' do
        expect(server['groupId']).to eq(params['groupId'])
      end

      it 'launches server with specified template' do
        expect(server['os']).to eq('centOS6_64Bit')
      end

      it 'sets specified number of CPUs' do
        expect(server['details']['cpu']).to eq(params['cpu'])
      end

      it 'sets specified amount of RAM' do
        expected_memory = params['memoryGB'] * 1024
        expect(server['details']['memoryMB']).to eq(expected_memory)
      end

      it 'launches server of specified type' do
        expect(server['type']).to eq(params['type'])
      end
    end
  end

  describe '#list_datacenters' do
    context 'with cloud success', with_vcr('client/list_datacenters/success') do
      it 'returns a list of datatacenters' do
        expect(subject.list_datacenters).to be_an(Array)
      end
    end
  end

  describe '#show_datacenter' do
    context 'with group links option', with_vcr('client/show_datacenter/with_groups') do
      it 'returns datacenters with group links' do
        response = subject.show_datacenter('ca1', true)
        group_link = response['links'].detect { |link| link['rel'] == 'group' }
        expect(group_link).to be_an(Hash)
      end
    end

    context 'without group links option', with_vcr('client/show_datacenter/without_groups') do
      it 'returns datacenters without group links' do
        response = subject.show_datacenter('ca1', false)
        group_link = response['links'].detect { |link| link['rel'] == 'group' }
        expect(group_link).to be_nil
      end
    end
  end

  describe '#show_group' do
    context 'with cloud success', with_vcr('client/show_group/success') do
      it 'returns groups details withing sub groups and their details' do
        response = subject.show_group('5ffda89a8ce6444baa8d28b9d1581e6d')
        expect(response['id']).to eq('5ffda89a8ce6444baa8d28b9d1581e6d')
      end
    end
  end

  describe '#list_groups' do
    context 'within datacenter', with_vcr('client/list_groups/success') do
      it 'returns a list of datacenters groups' do
        response = subject.list_groups('ca1')
        expect(response).to be_an(Array)
        expect(response.map { |group| group['groups'] }).to all(be_nil)
      end
    end
  end

  describe '#list_templates' do
    context 'when datacenter specified' do
      context 'and exists', with_vcr('client/list_templates/datacenter_exists') do
        let(:datacenter_id) { 'ca1' }

        it 'returns an Array' do
          expect(client.list_templates('ca1')).to be_an(Array)
        end
      end

      context 'and does not exist', with_vcr('client/list_templates/datacenter_does_not_exist') do
        let(:datacenter_id) { 'does-not-exist' }

        it 'fails' do
          expect { client.list_templates(datacenter_id) }.to raise_error
        end
      end
    end

    context 'when datacenter is not specified', with_vcr('client/list_templates/without_datacenter') do
      it 'fails' do
        expect { client.list_templates }.to raise_error(ArgumentError)
      end
    end
  end
end
