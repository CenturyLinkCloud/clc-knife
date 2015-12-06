require 'chef/knife'
require 'chef/knife/clc_ip_create'

describe Chef::Knife::ClcIpCreate do
  subject(:command) { Chef::Knife::ClcIpCreate.new }

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

    before(:each) do
      command.config[:clc_wait] = true
      command.config[:clc_server] = server_id

      allow(command).to receive(:connection) { connection }
      allow(command.ui).to receive(:info) { |msg| puts msg }

      allow(connection).to receive(:create_ip_address) do
        { 'operation' => ip_assignment_link }
      end

      allow(connection).to receive(:wait_for) do |&block|
        4.times { block.call }
      end
    end

    let(:connection) { double }
    let(:server_id) { 'ca1altdtest43' }

    let(:ip_assignment_link) do
      {
        'rel' => 'status',
        'href' => '/v2/operations/altd/status/ca1-41967',
        'id' => 'ca1-41967'
      }
    end

    context 'without waiting' do
      before(:each) do
        command.config.delete(:clc_wait)
      end

      it { is_expected.to output(/ip assignment request has been sent/i).to_stdout_from_any_process }
      it { is_expected.to output(/knife clc operation show #{ip_assignment_link['id']}/).to_stdout_from_any_process }
    end

    context 'with waiting' do
      it { is_expected.to output(/public ip has been assigned/i).to_stdout_from_any_process }
      it { is_expected.to output(/knife clc server show #{server_id} --ip-details/).to_stdout_from_any_process }
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

      it { is_expected.to include(match(/server id is required/i)) }
      it { is_expected.to include(match(/protocol definition is required/i)) }
    end

    context 'considering complex parameters' do
      subject(:config) do
        command.parse_options(argv)
        command.parse_and_validate_parameters
        command.config
      end

      context 'when they are valid' do
        let(:argv) do
          %w(
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
            --source 0.0.0.0/0
            --source 10.0.0.0/0
          )
        end

        let(:expected_sources) do
          [
            { 'cidr' => '0.0.0.0/0' },
            { 'cidr' => '10.0.0.0/0' }
          ]
        end

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

        it { is_expected.to include(:clc_sources => expected_sources) }
        it { is_expected.to include(:clc_allowed_protocols => expected_protocols) }
      end
    end

    describe 'when they are malformed' do
      subject(:errors) do
        command.parse_options(argv)
        command.parse_and_validate_parameters
        command.errors
      end

      let(:argv) do
        %w(
          --allow unknownProtocol
          --allow udp:20-21-24
          --allow tcp
        )
      end

      it { is_expected.to include(/unknownProtocol/) }
      it { is_expected.to include(/udp:20-21-24/) }
      it { is_expected.to include(/tcp/) }
    end
  end
end
