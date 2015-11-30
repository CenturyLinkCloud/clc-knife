require 'chef/knife'
require 'chef/knife/clc_server_create'

describe Chef::Knife::ClcServerCreate do
  subject(:command) { Chef::Knife::ClcServerCreate.new }

  describe '#execute' do
    subject(:execute) { -> { command.execute } }

    before(:each) do
      allow(command).to receive(:config_file_settings) { {} }
      command.configure_chef
      command.config[:clc_wait] = true
      command.config[:clc_allowed_protocols] = [{ 'protocol' => 'tcp', 'port' => 23 }]

      allow(command).to receive(:connection) { connection }
      allow(command.ui).to receive(:info) { |msg| puts msg }
      allow(connection).to receive(:follow) do |link|
        link['rel'] == 'credentials' ? credentials : server
      end

      allow(connection).to receive(:create_server) do
        { 'operation' => server_creation_link, 'resource' => server_link }
      end

      allow(connection).to receive(:add_public_ip) do
        { 'operation' => ip_assignment_link }
      end

      allow(connection).to receive(:wait_for) do |&block|
        4.times { block.call }
      end
    end

    let(:connection) { double }

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
        'description' => '',
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

    let(:credentials) do
      { 'userName' => 'root', 'password' => 'somePassword' }
    end

    context 'without waiting and without public IP' do
      before(:each) do
        command.config.delete(:clc_wait)
        command.config.delete(:clc_allowed_protocols)
      end

      it { is_expected.to output(/launch request has been sent/i).to_stdout_from_any_process }
      it { is_expected.to output(/knife clc operation show #{server_creation_link['id']}/).to_stdout_from_any_process }
      it { is_expected.to output(/knife clc server show #{server_link['id']} --uuid/).to_stdout_from_any_process }
      it { is_expected.to_not output(/#{server['id']}/).to_stdout_from_any_process }
    end

    context 'without waiting but with public IP' do
      before(:each) do
        command.config.delete(:clc_wait)
      end

      it { is_expected.to output(/launch request has been sent/i).to_stdout_from_any_process }
      it { is_expected.to output(/ip request has been sent/i).to_stdout_from_any_process }
      it { is_expected.to output(/knife clc operation show #{server_creation_link['id']}/).to_stdout_from_any_process }
      it { is_expected.to output(/knife clc operation show #{ip_assignment_link['id']}/).to_stdout_from_any_process }
      it { is_expected.to output(/knife clc server show #{server_link['id']} --uuid/).to_stdout_from_any_process }
      it { is_expected.to_not output(/#{server['id']}/).to_stdout_from_any_process }
    end

    context 'with waiting but without public IP' do
      it { is_expected.to output(/server has been launched/i).to_stdout_from_any_process }
      it { is_expected.to output(/Name/).to_stdout_from_any_process }
      it { is_expected.to output(/#{server['name']}/).to_stdout_from_any_process }
      it { is_expected.to_not output(/knife clc/).to_stdout_from_any_process }
    end

    context 'with waiting and with public IP' do
      it { is_expected.to output(/server has been launched/i).to_stdout_from_any_process }
      it { is_expected.to output(/ip has been assigned/i).to_stdout_from_any_process }
      it { is_expected.to output(/Name/).to_stdout_from_any_process }
      it { is_expected.to output(/Username/).to_stdout_from_any_process }
      it { is_expected.to output(/Password/).to_stdout_from_any_process }
      it { is_expected.to output(/Public IP/).to_stdout_from_any_process }
      it { is_expected.to output(/#{server['name']}/).to_stdout_from_any_process }
      it { is_expected.to output(/#{Regexp.quote(server['details']['ipAddresses'].last['public'])}/).to_stdout_from_any_process }
      it { is_expected.to output(/#{credentials['userName']}/).to_stdout_from_any_process }
      it { is_expected.to output(/#{credentials['password']}/).to_stdout_from_any_process }
      it { is_expected.to_not output(/knife clc/).to_stdout_from_any_process }
    end
  end

  describe '#parse_and_validate_parameters' do
    context 'considering required parameters' do
      subject(:errors) do
        command.parse_and_validate_parameters
        command.errors
      end

      it { is_expected.to include(match(/name is required/i)) }
      it { is_expected.to include(match(/source id is required/i)) }
      it { is_expected.to include(match(/group id is required/i)) }
      it { is_expected.to include(match(/number of cpus is required/i)) }
      it { is_expected.to include(match(/number of memory gbs is required/i)) }
      it { is_expected.to include(match(/type is required/i)) }
    end

    context 'considering complex parameters' do
      subject(:config) do
        command.parse_and_validate_parameters
        command.config
      end

      before(:each) do
        command.config[:clc_custom_fields] = ['FIELD=VALUE']
        command.config[:clc_disks] = ['/dev/sda,10,raw']
        command.config[:clc_packages] = ['editor,LICENSE=FREE']
        command.config[:clc_allowed_protocols] = ['tcp:23-24']
      end

      let(:expected_fields) { [{ 'id' => 'FIELD', 'value' => 'VALUE' }] }
      let(:expected_packages) { [{ 'packageId' => 'editor', 'parameters' => [{ 'LICENSE' => 'FREE' }] }] }
      let(:expected_disks) { [{ 'path' => '/dev/sda', 'sizeGB' => '10', 'type' => 'raw' }] }
      let(:expected_protocols) { [{'protocol' => 'tcp', 'port' => '23', 'portTo' => '24' }] }

      it { is_expected.to include(:clc_custom_fields => expected_fields) }
      it { is_expected.to include(:clc_packages => expected_packages) }
      it { is_expected.to include(:clc_disks => expected_disks) }
      it { is_expected.to include(:clc_allowed_protocols => expected_protocols) }
    end
  end
end
