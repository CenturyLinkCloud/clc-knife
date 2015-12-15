require 'chef/knife/clc_ip_delete'

describe Chef::Knife::ClcIpDelete do
  let(:valid_argv) do
    %w(
      68.44.12.101
      --server ca1altdtest43
    )
  end

  it_behaves_like 'a Knife CLC command' do
    let(:argv) { valid_argv }
  end

  include_context 'a Knife command'

  let(:server_id) { 'ca1altdtest43' }
  let(:ip_string) { '68.44.12.101' }

  let(:ip_removal_link) do
    {
      'rel' => 'status',
      'href' => '/v2/operations/altd/status/ca1-41967',
      'id' => 'ca1-41967'
    }
  end

  before(:each) do
    allow(connection).to receive(:delete_ip_address).with(server_id, ip_string) do
      { 'operation' => ip_removal_link }
    end

    allow(connection).to receive(:wait_for) do |&block|
      4.times { block.call }
    end
  end

  context 'considering displayed information' do
    before(:each) { run.call }

    subject(:output) { stdout.string }

    context 'without waiting' do
      let(:argv) { valid_argv }

      it { is_expected.to match(/deletion request has been sent/i) }
      it { is_expected.to match(/knife clc operation show #{ip_removal_link['id']}/) }
    end

    context 'with waiting' do
      let(:argv) { valid_argv.concat(%w(--wait)) }

      it { is_expected.to match(/ip address has been deleted/i) }
      it { is_expected.to match(/knife clc server show/) }
    end
  end

  context 'considering command parameters' do

    context 'when they are valid' do
      let(:argv) { valid_argv }

      it 'passes them correctly' do
        expect(connection).to receive(:delete_ip_address).with(server_id, ip_string)

        run.call
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

        it { is_expected.to match(/server id is required/i) }
        it { is_expected.to match(/ip string is required/i) }
      end
    end
  end
end
