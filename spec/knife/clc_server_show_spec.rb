require 'chef/knife/clc_server_show'

describe Chef::Knife::ClcServerShow do
  it_behaves_like 'a Knife CLC command' do
    let(:argv) { %w(ca1altdtest55) }
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
          { 'public' => '65.39.180.9', 'internal' => '10.50.48.13' },
          { 'public' => '65.39.180.75', 'internal' => '10.50.48.14' },
          { 'public' => '65.39.180.227', 'internal' => '10.50.48.15' },
          { 'public' => '65.39.180.185', 'internal' => '10.50.48.16' },
          { 'public' => '65.39.180.186', 'internal' => '10.50.48.17' }
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

  let(:creds) { { 'userName' => 'root', 'password' => 'safePassword' } }

  let(:ip_addresses) do
    [
      {
        'internalIPAddress' => '10.50.48.13',
        'ports' => [{ 'protocol' => 'TCP', 'port' => 22 }],
        'sourceRestrictions' => [],
        'id' => '65.39.180.9'
      },
      {
        'internalIPAddress' => '10.50.48.14',
        'ports' => [{ 'protocol' => 'TCP', 'port' => 22 }],
        'sourceRestrictions' => [],
        'id' => '65.39.180.75'
      },
      {
        'internalIPAddress' => '10.50.48.15',
        'ports' => [{ 'protocol' => 'TCP', 'port' => 22 }],
        'sourceRestrictions' => [],
        'id' => '65.39.180.227'
      },
      {
        'internalIPAddress' => '10.50.48.16',
        'ports' => [{ 'protocol' => 'ICMP', 'port' => 0 }, {'protocol' => 'TCP', 'port' => 443 }],
        'sourceRestrictions' => [{ 'cidr' => '10.0.0.0/32' }],
        'id' => '65.39.180.185'
      },
      {
        'internalIPAddress' => '10.50.48.17',
        'ports' => [{ 'protocol' => 'ICMP', 'port' => 0 }, { 'protocol' => 'TCP', 'port' => 443 }],
        'sourceRestrictions' => [{ 'cidr' => '10.0.0.0/32' }],
        'id' => '65.39.180.186'
      }
    ]
  end

  before(:each) do
    allow(connection).to receive(:show_server).with(server['id'], false) { server }
    allow(connection).to receive(:follow).with(server['links'].first) { creds }
    allow(connection).to receive(:list_ip_addresses).with(server['id']) { ip_addresses }
  end

  context 'with valid parameters' do
    let(:argv) { %w(ca1altdtest55) }

    context 'considering system status' do
      it { is_expected.not_to raise_error }
    end

    context 'considering displayed data' do
      subject(:output) do
        run.call
        stdout.string
      end

      context 'when server is under construction and details are not available' do
        before(:each) do
          server.delete('details')
        end

        it { is_expected.to match(/Power State/i) }
        it { is_expected.to match(/CPUs/i) }
        it { is_expected.to match(/Memory/i) }
        it { is_expected.to match(/Storage/i) }
        it { is_expected.to match(/Public IPs/i) }
        it { is_expected.to match(/Private IPs/i) }
      end

      context 'what is is shown for a launched server' do
        it { is_expected.to match(/ID/i) }
        it { is_expected.to match(/Name/i) }
        it { is_expected.to match(/Description/i) }
        it { is_expected.to match(/Location/i) }
        it { is_expected.to match(/Group/i) }
        it { is_expected.to match(/OS Type/i) }
        it { is_expected.to match(/Status/i) }
        it { is_expected.to match(/Power State/i) }
        it { is_expected.to match(/CPUs/i) }
        it { is_expected.to match(/Memory/i) }
        it { is_expected.to match(/Storage/i) }
        it { is_expected.to match(/Public IPs/i) }
        it { is_expected.to match(/Private IPs/i) }

        it { is_expected.to include(server['id']) }
        it { is_expected.to include(server['name']) }
        it { is_expected.to include(server['description']) }
        it { is_expected.to include(server['locationId']) }
        it { is_expected.to include(server['groupId']) }
        it { is_expected.to include(server['osType']) }
        it { is_expected.to include(server['status']) }
        it { is_expected.to include(server['details']['cpu'].to_s) }
        it { is_expected.to include("#{server['details']['memoryMB']} MB") }
        it { is_expected.to include("#{server['details']['storageGB']} GB") }
      end

      context 'what is shown with creds option' do
        let(:argv) { %w(ca1altdtest55 --creds) }

        context 'when there is a link to creds available' do
          it { is_expected.to match(/Username/i) }
          it { is_expected.to match(/Password/i) }

          it { is_expected.to include(creds['userName']) }
          it { is_expected.to include(creds['password']) }
        end

        context 'when there is no link to creds' do
          before(:each) do
            server['links'].delete_if { |link| link['rel'] == 'credentials' }
          end

          it { is_expected.to match(/Username/i) }
          it { is_expected.to match(/Password/i) }
        end
      end

      context 'what is shown with ports option' do
        let(:argv) { %w(ca1altdtest55 --ports) }
        let(:sample_ip) { ip_addresses.last }

        context 'when there are links to IP addresses available' do
          it { is_expected.to match(/Public IP/i) }
          it { is_expected.to match(/Internal IP/i) }
          it { is_expected.to match(/Ports/i) }
          it { is_expected.to match(/Sources/i) }

          it { is_expected.to include(sample_ip['id']) }
          it { is_expected.to include(sample_ip['internalIPAddress']) }
          it { is_expected.to include(sample_ip['ports'].last['protocol']) }
          it { is_expected.to include(sample_ip['ports'].last['port'].to_s) }
          it { is_expected.to include(sample_ip['sourceRestrictions'].first['cidr']) }
        end

        context 'when there are no IP address info available' do
          before(:each) do
            allow(connection).to receive(:list_ip_addresses) { [] }
          end

          it { is_expected.to match(/no additional networking info available/i) }
        end
      end
    end
  end

  context 'without a server ID' do
    context 'considering system status' do
      it { is_expected.to raise_error(/SystemExit/) }
    end

    context 'considering output' do
      before(:each) do
        allow(command).to receive(:exit)
        run.call
      end

      context 'to STDOUT' do
        subject(:output) { stdout.string }

        it { is_expected.to match(/USAGE/i) }
      end

      context 'to STDERR' do
        subject(:errors) { stderr.string }

        it { is_expected.to match(/server id is required/i) }
      end
    end
  end
end
