require 'chef/knife/clc_datacenter_list'

describe Chef::Knife::ClcDatacenterList do
  it_behaves_like 'a Knife CLC command'

  include_context 'a Knife command'

  let(:datacenter) do
    {
      'id' => 'ca1',
      'name' => 'CA1 - Canada (Vancouver)',
      'links' => [{ 'rel' => 'self', 'href' => '/v2/datacenters/altd/ca1' }]
    }
  end

  before(:each) do
    allow(connection).to receive(:list_datacenters) { [datacenter] }
  end

  context 'considering system status' do
    it { is_expected.not_to raise_error }
  end

  context 'considering displayed data' do
    subject(:output) do
      run.call
      stdout.string
    end

    context 'considering fields that are always shown' do
      it { is_expected.to include(datacenter['name']) }
      it { is_expected.to include(datacenter['id']) }
    end

    context 'considering headers' do
      it { is_expected.to match(/Name/i) }
      it { is_expected.to match(/ID/i) }
    end

    context 'considering ignored fields' do
      before(:each) { datacenter['unknownField'] = 'Something' }

      it { is_expected.to_not match(%r[v2/datacenters/altd]) }
      it { is_expected.to_not match(/unknownField/) }
      it { is_expected.to_not match(/Something/) }
    end

    context 'considering situation when there is no data to display' do
      before(:each) { allow(connection).to receive(:list_datacenters) { [] } }

      it { is_expected.to_not match(/\w/) }
    end
  end
end
