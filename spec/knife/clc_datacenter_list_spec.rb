require 'chef/knife'
require 'chef/knife/clc_datacenter_list'

describe Chef::Knife::ClcDatacenterList do
  subject(:command) { Chef::Knife::ClcDatacenterList.new }

  describe '#run' do
    subject(:run) { -> { command.run } }

    let(:connection) { double }

    before(:each) do
      allow(command).to receive(:connection) { connection }
      allow(command).to receive(:exit)
      allow(connection).to receive(:list_datacenters) { [] }
    end

    context 'considering displayed information' do
      context 'when there is data available' do
        before(:each) do
          allow(connection).to receive(:list_datacenters) { [datacenter] }
        end

        let(:datacenter) do
          {
            'id' => 'ca1',
            'name' => 'CA1 - Canada (Vancouver)',
            'links' => [{ 'rel' => 'self', 'href' => '/v2/datacenters/altd/ca1' }]
          }
        end

        context 'considering fields that are always shown' do
          it { is_expected.to output(/#{Regexp.quote(datacenter['name'])}/).to_stdout_from_any_process }
          it { is_expected.to output(/#{datacenter['id']}/).to_stdout_from_any_process }
        end

        context 'considering headers' do
          it { is_expected.to output(/Name/).to_stdout_from_any_process }
          it { is_expected.to output(/ID/).to_stdout_from_any_process }
        end

        context 'considering ignored fields' do
          before(:each) { datacenter['unknownField'] = 'Something' }

          it { is_expected.to_not output(%r[v2/datacenters/altd]).to_stdout_from_any_process }
          it { is_expected.to_not output(/unknownField/).to_stdout_from_any_process }
          it { is_expected.to_not output(/Something/).to_stdout_from_any_process }
        end
      end

      context 'when there is no data available' do
        it { is_expected.to_not output(/./).to_stdout_from_any_process }
      end
    end
  end
end
