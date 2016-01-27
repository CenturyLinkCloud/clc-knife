require 'chef/knife/clc_server_create'

describe Chef::Knife::ClcServerCreate do
  let(:valid_argv) do
    %w(
      --name test
      --source-server DEBIAN-7-64-TEMPLATE
      --group 975a79f94b84452ea1c920325967a33c
      --cpu 1
      --memory 1
      --type standard
    )
  end

  let(:server_link) do
    {
      'rel' => 'self',
      'href' => '/v2/servers/ALTD/2a1c7cf8e8e341dcbe606dc8b7e3600b?uuid=True',
      'id' => '2a1c7cf8e8e341dcbe606dc8b7e3600b'
    }
  end

  let(:server_creation_link) do
    {
      'rel' => 'status',
      'href' => '/v2/operations/altd/status/ca1-41967',
      'id' => 'ca1-41967'
    }
  end

  let(:ip_assignment_link) do
    {
      'rel' => 'status',
      'href' => '/v2/operations/altd/status/ca1-41969',
      'id' => 'ca1-41969'
    }
  end

  let(:server) do
    {
      'id' => 'ca1altdtest40',
      'name' => 'CA1ALTDTEST40',
      'description' => 'descr',
      'groupId' => '975a79f94b84452ea1c920325967a33c',
      'isTemplate' => false,
      'locationId' => 'CA1',
      'osType' => 'Debian 7 64-bit',
      'os' => 'debian7_64Bit',
      'status' => 'active',
      'details' => {
        'ipAddresses' => [
          { 'internal' => '10.50.48.14' },
          { 'public' => '64.69.71.199', 'internal' => '10.50.48.15' }
        ],
        'secondaryIPAddresses' => [],
        'alertPolicies' => [],
        'cpu' => 1,
        'diskCount' => 3,
        'hostName' => 'ca1altdtest40',
        'inMaintenanceMode' => false,
        'memoryMB' => 1024,
        'powerState' => 'started',
        'storageGB' => 19,
        'disks' => [
          { 'id' => '0:0', 'sizeGB' => 1, 'partitionPaths' => [] },
          { 'id' => '0:1', 'sizeGB' => 2, 'partitionPaths' => [] },
          { 'id' => '0:2', 'sizeGB' => 16, 'partitionPaths' => [] }
        ],
        'partitions' => [
          { 'sizeGB' => 0.0, 'path' => '(swap)' },
          { 'sizeGB' => 15.748, 'path' => '/' },
          { 'sizeGB' => 0.482, 'path' => '/boot' }
        ],
        'snapshots' => [],
        'customFields' => []
      },
      'type' => 'standard',
      'storageType' => 'premium',
      'links' => [
        {
          'rel' => 'credentials',
          'href' => '/v2/servers/altd/ca1altdtest40/credentials'
        },
        {
          'rel' => 'publicIPAddress',
          'href' => '/v2/servers/altd/ca1altdtest40/publicIPAddresses/64.69.71.199',
          'id' => '64.69.71.199'
        }
      ]
    }
  end

  let(:group) do
    {
      'id' => '975a79f94b84452ea1c920325967a33c',
      'name' => 'test',
      'description' => 'descr',
      'locationId' => 'CA1',
      'type' => 'default',
      'status' => 'active'
    }
  end

  let(:template) do
    {
      'name' => 'DEBIAN-7-64-TEMPLATE',
      'osType' => 'debian7_64Bit',
      'description' => 'Debian 7 | 64-bit',
      'storageSizeGB' => 17,
      'capabilities' => ['cpuAutoscale'],
      'reservedDrivePaths' => ['bin'],
      'apiOnly' => true
    }
  end

  let(:credentials) { { 'userName' => 'root', 'password' => 'p@$$w0rT' } }

  let(:show_command) { double }

  let(:bootstrap_command) { double }

  let(:bootstrap_context) { double }

  it_behaves_like 'a Knife CLC command' do
    let(:argv) { valid_argv }
  end

  include_context 'a Knife command'

  before(:each) do
    allow(Chef::Knife::ClcServerShow).to receive(:new) { show_command }
    allow(show_command).to receive(:run)

    allow(connection).to receive(:follow) do |link|
      link['rel'] == 'credentials' ? credentials : server
    end

    allow(connection).to receive(:create_server) do
      { 'operation' => server_creation_link, 'resource' => server_link }
    end

    allow(connection).to receive(:create_ip_address) do
      { 'operation' => ip_assignment_link }
    end

    allow(connection).to receive(:wait_for) do |&block|
      4.times { block.call }
    end

    # TODO AS: Bootstrap related stubs and specs will be extracted
    allow(Chef::Knife::Bootstrap).to receive(:new) { bootstrap_command }
    allow(bootstrap_command).to receive(:run)
    allow(bootstrap_command).to receive(:config) { {} }
    allow(bootstrap_command).to receive(:configure_chef)
    allow(bootstrap_command).to receive(:name_args=)
    allow(bootstrap_command).to receive(:render_template)
    allow(bootstrap_command).to receive(:bootstrap_context) { bootstrap_context }
    allow(bootstrap_context).to receive(:validation_key) { 'KeyContents' }
    allow(Chef::Node).to receive(:list)
    allow(connection).to receive(:show_server).with(server_link['id'], true) { server }
    allow(connection).to receive(:show_group).with(group['id']) { group }
    allow(connection).to receive(:list_templates).with(group['locationId']) { [template] }
  end

  context 'considering displayed information' do
    subject(:output) do
      run.call
      stdout.string
    end

    context 'without bootstrapping' do
      context 'without waiting and without public IP' do
        let(:argv) { valid_argv }

        it { is_expected.to match(/launch request has been sent/i) }
        it { is_expected.to match(/knife clc operation show #{server_creation_link['id']}/) }
        it { is_expected.to match(/knife clc server show #{server_link['id']} --uuid/) }
        it { is_expected.to_not include(server['id']) }
      end

      context 'without waiting but with public IP' do
        let(:argv) { valid_argv.concat(%w(--allow ssh)) }

        it { is_expected.to match(/launch request has been sent/i) }
        it { is_expected.to match(/ip request has been sent/i) }
        it { is_expected.to match(/knife clc operation show #{server_creation_link['id']}/) }
        it { is_expected.to match(/knife clc operation show #{ip_assignment_link['id']}/) }
        it { is_expected.to match(/knife clc server show #{server_link['id']} --uuid/) }
        it { is_expected.to_not include(server['id']) }
      end

      context 'with waiting but without public IP' do
        let(:argv) { valid_argv.concat(%w(--wait)) }

        it { is_expected.to match(/server has been launched/i) }
        it { is_expected.to_not match(/knife clc/) }

        it 'requests output of server show command' do
          expect(show_command).to receive(:run)
          output
        end
      end

      context 'with waiting and with public IP' do
        let(:argv) { valid_argv.concat(%w(--wait --allow ssh)) }

        it { is_expected.to match(/server has been launched/i) }
        it { is_expected.to match(/ip has been assigned/i) }
        it { is_expected.to_not match(/knife clc/) }

        it 'requests output of server show command' do
          expect(show_command).to receive(:run)
          output
        end
      end
    end

    context 'with bootstrapping' do
      context 'without waiting and without public IP' do
        let(:argv) { valid_argv.concat(%w(--bootstrap)) }

        it { is_expected.to match(/bootstrap has been scheduled/i) }
        it { is_expected.to match(/launch request has been sent/i) }
        it { is_expected.to match(/knife clc operation show #{server_creation_link['id']}/) }
        it { is_expected.to match(/knife clc server show #{server_link['id']} --uuid/) }
        it { is_expected.to_not include(server['id']) }
      end

      context 'without waiting but with public IP' do
        let(:argv) { valid_argv.concat(%w(--bootstrap --allow ssh)) }

        it { is_expected.to match(/bootstrap has been scheduled/i) }
        it { is_expected.to match(/launch request has been sent/i) }
        it { is_expected.to match(/ip request has been sent/i) }
        it { is_expected.to match(/knife clc operation show #{server_creation_link['id']}/) }
        it { is_expected.to match(/knife clc operation show #{ip_assignment_link['id']}/) }
        it { is_expected.to match(/knife clc server show #{server_link['id']} --uuid/) }
        it { is_expected.to_not include(server['id']) }
      end

      context 'with waiting and with public IP' do
        let(:argv) { valid_argv.concat(%w(--bootstrap --wait --allow ssh)) }

        it { is_expected.to match(/server has been launched/i) }
        it { is_expected.to match(/ip has been assigned/i) }
        it { is_expected.to_not match(/knife clc/) }

        it 'requests output of server show command' do
          expect(show_command).to receive(:run)
          output
        end

        it 'requests output of bootstrap' do
          expect(bootstrap_command).to receive(:run)
          output
        end
      end
    end
  end

  context 'considering command parameters' do
    context 'when they are invalid' do
      before(:each) do
        allow(command).to receive(:exit)
        run.call
      end

      subject(:output) { stderr.string }

      context 'meaning required ones are missing' do
        let(:argv) { [] }

        it { is_expected.to match(/name is required/i) }
        it { is_expected.to match(/source server id is required/i) }
        it { is_expected.to match(/group id is required/i) }
        it { is_expected.to match(/number of cpus is required/i) }
        it { is_expected.to match(/number of memory gbs is required/i) }
        it { is_expected.to match(/type is required/i) }
      end

      context 'meaning complex ones are malformed' do
        let(:argv) do
          %w(
            --custom-field FIELDVALUE
            --disk /dev/sda10,raw
            --package editorLICENSEFREE
            --allow unknownProtocol
            --allow udp:20-21-24
            --allow tcp
          )
        end

        it { is_expected.to include('FIELDVALUE') }
        it { is_expected.to include('/dev/sda10,raw') }
        it { is_expected.to include('editorLICENSEFREE') }
        it { is_expected.to include('unknownProtocol') }
        it { is_expected.to include('udp:20-21-24') }
        it { is_expected.to include('tcp') }
      end

      context 'meaning that sync bootstrap is requested but there is no public IP' do
        let(:argv) { %w(--bootstrap --wait) }

        it { is_expected.to include('requires public IP access to the server') }
      end
    end

    context 'when they are valid' do
      let(:argv) do
        valid_argv.concat(%w(
          --custom-field FIELD=VALUE
          --disk /dev/sda,10,raw
          --package editor,LICENSE=FREE
          --source 0.0.0.0/0
          --source 10.0.0.0/0
          --allow ssh
          --allow http
          --allow rdp
          --allow icmp
          --allow http
          --allow https
          --allow ftp
          --allow ftps
          --allow udp:20-21
          --allow tcp:91
        ))
      end

      let(:expected_fields) { [{ 'id' => 'FIELD', 'value' => 'VALUE' }] }
      let(:expected_packages) { [{ 'packageId' => 'editor', 'parameters' => { 'LICENSE' => 'FREE' } }] }
      let(:expected_disks) { [{ 'path' => '/dev/sda', 'sizeGB' => '10', 'type' => 'raw' }] }
      let(:expected_sources) { [{ 'cidr' => '0.0.0.0/0' }, { 'cidr' => '10.0.0.0/0' }] }
      let(:expected_protocols) do
        [
          { 'protocol' => 'tcp', 'port' => 22 },
          { 'protocol' => 'tcp', 'port' => 80 },
          { 'protocol' => 'tcp', 'port' => 8080 },
          { 'protocol' => 'tcp', 'port' => 3389 },
          { 'protocol' => 'icmp' },
          { 'protocol' => 'tcp', 'port' => 80 },
          { 'protocol' => 'tcp', 'port' => 8080 },
          { 'protocol' => 'tcp', 'port' => 443 },
          { 'protocol' => 'tcp', 'port' => 21 },
          { 'protocol' => 'tcp', 'port' => 990 },
          { 'protocol' => 'udp', 'port' => 20, 'portTo' => 21 },
          { 'protocol' => 'tcp', 'port' => 91 }
        ]
      end

      it 'passes server params correctly' do
        expected_server_params = {
          'name' => 'test',
          'sourceServerId' => 'DEBIAN-7-64-TEMPLATE',
          'groupId' => '975a79f94b84452ea1c920325967a33c',
          'cpu' => 1,
          'memoryGB' => 1,
          'type' => 'standard',
          'customFields' => expected_fields,
          'packages' => expected_packages,
          'additionalDisks' => expected_disks
        }

        expect(connection).to receive(:create_server).
          with(hash_including(expected_server_params)).
          and_return('operation' => server_creation_link, 'resource' => server_link)

        run.call
      end

      it 'passes IP params correctly' do
        expected_ip_params = {
          'ports' => expected_protocols,
          'sourceRestrictions' => expected_sources
        }

        expect(connection).to receive(:create_ip_address).
          with(server['id'], hash_including(expected_ip_params)).
          and_return('operation' => ip_assignment_link)

        run.call
      end
    end
  end
end
