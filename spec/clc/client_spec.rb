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
end
