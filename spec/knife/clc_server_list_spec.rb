require 'chef/knife/clc_server_list'

describe Chef::Knife::ClcServerList do
  let(:valid_argv) { %w(--datacenter ca1) }

  it_behaves_like 'a Knife CLC command' do
    let(:argv) { valid_argv }
  end

  include_context 'a Knife command'

  let(:server) do
    {
      'id' => 'ca1altdtest55',
      'name' => 'CA1ALTDTEST55',
      'description' => 'Some description',
      'groupId' => '975a79f94b84452ea1c920325967a33c',
      'isTemplate' => false,
      'locationId' => 'CA1',
      'osType' => 'Debian 7 64-bit',
      'os' => 'debian7_64Bit',
      'status' => 'active',
      'details' => {
        'ipAddresses' => [
          { 'internal' => '10.50.48.12' },
          { 'public' => '65.39.180.227', 'internal' => '10.50.48.15' }
        ],
        'secondaryIPAddresses' => [],
        'alertPolicies' => [],
        'cpu' => 1,
        'diskCount' => 3,
        'hostName' => 'ca1altdtest55',
        'inMaintenanceMode' => false,
        'memoryMB' => 1024,
        'powerState' => 'started',
        'storageGB' => 19,
        'snapshots' => [],
        'customFields' => []
      },
      'type' => 'standard',
      'storageType' => 'premium',
      'links' => [
        { 'rel' => 'credentials', 'href' => '/v2/servers/altd/ca1altdtest55/credentials' },
        { 'rel' => 'publicIPAddress', 'href' => '/v2/servers/altd/ca1altdtest55/publicIPAddresses/65.39.180.227', 'id' => '65.39.180.227' }
      ]
    }
  end

  let(:datacenter) { { 'id' => 'ca1' } }

  before(:each) do
    allow(connection).to receive(:list_servers) { [server] }
    allow(connection).to receive(:list_datacenters) { [datacenter] }
  end

  context 'considering displayed information' do
    let(:argv) { valid_argv }

    subject(:output) do
      run.call
      stdout.string
    end

    context 'which is always shown' do
      it { is_expected.to include(server['name']) }
      it { is_expected.to include(server['links'].last['id']) }
      it { is_expected.to include(server['status']) }

      # TODO AS: Displaying shortened list of fields for now
      # it { is_expected.to include(server['id']) }
      # it { is_expected.to include(server['groupId']) }
      # it { is_expected.to include(server['locationId']) }
      # it { is_expected.to include(server['osType']) }

      it { is_expected.to match(/Name/i) }
      it { is_expected.to match(/Public IP/i) }
      it { is_expected.to match(/Status/i) }

      # TODO AS: Displaying shortened list of fields for now
      # it { is_expected.to match(/ID/i) }
      # it { is_expected.to match(/Group/i) }
      # it { is_expected.to match(/DC/i) }
      # it { is_expected.to match(/OS Type/i) }
    end

    context 'with chef nodes parameter' do
      let(:argv) { valid_argv.concat(%w(--chef-nodes)) }
      let(:node) { double(:name => server['name'] + '.local', :[] => server['name']) }

      before(:each) do
        allow(Chef::Node).to receive(:list) { { node.name => node } }
      end

      it { is_expected.to match(/Chef Node/) }
      it { is_expected.to include(node.name) }
    end
  end

  context 'considering command parameters' do
    context 'when they are valid' do
      context 'meaning datacenter is specified' do
        let(:argv) { valid_argv }

        it 'passes them correctly' do
          expect(connection).to receive(:list_servers).with(datacenter['id'])

          run.call
        end
      end

      context 'meaning all option is specified' do
        let(:argv) { %w(--all) }

        it 'passes them correctly' do
          expect(connection).to receive(:list_servers).with(datacenter['id'])

          run.call
        end
      end
    end

    context 'when they are invalid' do
      before(:each) do
        allow(command).to receive(:exit)
        run.call
      end

      subject(:output) { stderr.string }

      context 'meaning that required ones are missing' do
        let(:argv) { [] }

        it { is_expected.to match(/datacenter id is required/i) }
      end
    end
  end
end
