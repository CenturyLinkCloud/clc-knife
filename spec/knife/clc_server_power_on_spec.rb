require 'chef/knife/clc_server_power_on'

describe Chef::Knife::ClcServerPowerOn do
  let(:valid_argv) { %w(ca1altdtest43) }

  it_behaves_like 'a Knife CLC command' do
    let(:argv) { valid_argv }
  end

  include_context 'a Knife command'

  let(:server_id) { 'ca1altdtest43' }

  let(:server_power_on_link) do
    {
      'rel' => 'status',
      'href' => '/v2/operations/altd/status/ca1-41967',
      'id' => 'ca1-41967'
    }
  end

  before(:each) do
    allow(connection).to receive(:power_on_server) do
      { 'operation' => server_power_on_link }
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

      it { is_expected.to match(/power on request has been sent/i) }
      it { is_expected.to match(/knife clc operation show #{server_power_on_link['id']}/) }
    end

    context 'with waiting' do
      let(:argv) { valid_argv.concat(%w(--wait)) }

      it { is_expected.to match(/server has been powered on/i) }
      it { is_expected.to_not match(/knife clc/) }
    end
  end

  context 'considering command parameters' do
    context 'when they are valid' do
      let(:argv) { valid_argv }

      it 'passes them correctly' do
        expect(connection).to receive(:power_on_server).
          with(server_id).
          and_return('operation' => server_power_on_link)

        run.call
      end
    end

    context 'when they are invalid' do
      before(:each) do
        allow(command).to receive(:exit)
        run.call
      end

      subject(:output) { stderr.string }

      context 'meaning required ones are missing' do
        let(:argv) { [] }

        it { is_expected.to match(/server id is required/i) }
      end
    end
  end
end
