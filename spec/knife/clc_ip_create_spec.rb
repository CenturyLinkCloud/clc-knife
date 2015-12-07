require 'chef/knife/clc_ip_create'

describe Chef::Knife::ClcIpCreate do
  let(:valid_argv) do
    %w(
      --server ca1altdtest43
      --allow ssh
    )
  end

  it_behaves_like 'a Knife CLC command' do
    let(:argv) { valid_argv }
  end

  include_context 'a Knife command'

  let(:server_id) { 'ca1altdtest43' }

  let(:ip_assignment_link) do
    {
      'rel' => 'status',
      'href' => '/v2/operations/altd/status/ca1-41967',
      'id' => 'ca1-41967'
    }
  end

  before(:each) do
    allow(connection).to receive(:create_ip_address) do
      { 'operation' => ip_assignment_link }
    end

    allow(connection).to receive(:wait_for) do |&block|
      4.times { block.call }
    end
  end

  context 'considering displayed information' do
    subject(:output) do
      run.call
      stdout.string
    end

    context 'without waiting' do
      let(:argv) { valid_argv }

      it { is_expected.to match(/ip assignment request has been sent/i) }
      it { is_expected.to match(/knife clc operation show #{ip_assignment_link['id']}/) }
    end

    context 'with waiting' do
      let(:argv) { valid_argv.concat(%w(--wait)) }

      it { is_expected.to match(/public ip has been assigned/i) }
      it { is_expected.to match(/knife clc server show #{server_id} --ports/) }
    end
  end

  context 'considering command parameters' do
    context 'when they are invalid' do
      before(:each) do
        allow(command).to receive(:exit)
        run.call
      end

      subject(:output) { stderr.string }

      context 'meaning that required ones are missing' do
        let(:argv) { [] }

        it { is_expected.to match(/server id is required/i) }
        it { is_expected.to match(/protocol permission is required/i) }
      end

      context 'meaning that complex ones are malformed' do
        let(:argv) do
          %w(
            --allow unknownProtocol
            --allow udp:20-21-24
            --allow tcp
          )
        end

        it { is_expected.to match(/unknownProtocol/) }
        it { is_expected.to match(/udp:20-21-24/) }
        it { is_expected.to match(/tcp/) }
      end
    end

    context 'when they are valid' do
      let(:argv) do
        %w(
          --internal 10.0.0.1
          --server ca1altdtest43
          --allow udp:20-21
          --allow icmp
          --allow ssh
          --allow rdp
          --allow http
          --allow https
          --allow ftp
          --allow ftps
          --allow tcp:91
          --source 0.0.0.0/0
          --source 10.0.0.0/0
        )
      end

      it 'passes them correctly' do
        expected_params = {
          'internalIPAddress' => '10.0.0.1',
          'ports' => [
            { 'protocol' => 'udp', 'port' => 20, 'portTo' => 21 },
            { 'protocol' => 'icmp' },
            { 'protocol' => 'tcp', 'port' => 22 },
            { 'protocol' => 'tcp', 'port' => 3389 },
            { 'protocol' => 'tcp', 'port' => 80 },
            { 'protocol' => 'tcp', 'port' => 8080 },
            { 'protocol' => 'tcp', 'port' => 443 },
            { 'protocol' => 'tcp', 'port' => 21 },
            { 'protocol' => 'tcp', 'port' => 990 },
            { 'protocol' => 'tcp', 'port' => 91 }
          ],
          'sourceRestrictions' => [
            { 'cidr' => '0.0.0.0/0' },
            { 'cidr' => '10.0.0.0/0' }
          ]
        }

        expect(connection).to receive(:create_ip_address).
          with('ca1altdtest43', hash_including(expected_params)).
          and_return('operation' => ip_assignment_link)

        run.call
      end
    end
  end
end
