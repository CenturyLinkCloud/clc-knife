shared_examples_for 'async operation' do
  it { is_expected.to be_a(Hash) }
  it { is_expected.to include('operation') }
end

describe Clc::Client do
  subject(:client) { Clc::Client.new }

  describe '#list_servers' do
    context 'with cloud success', with_vcr('client/list_servers/success') do
      it 'returns an Array' do
        expect(client.list_servers('ca1')).to be_an(Array)
      end
    end

    context 'with cloud failure', with_vcr('client/list_servers/failure') do
      it 'raises an error' do
        expect { client.list_servers('not-real') }.to raise_error(Clc::CloudExceptions::Error)
      end
    end
  end

  describe '#create_group' do
    let(:params) do
      {
        'name' => 'group name',
        'description' => 'group description',
        'parentGroupId' => '975a79f94b84452ea1c920325967a33c',
      }
    end

    context 'with valid params', with_vcr('client/create_group/valid') do
      subject(:creation_response) { client.create_group(params) }

      it 'returns data about created group' do
        expect(creation_response['name']).to eq 'group name'
      end
    end
  end

  describe '#create_server' do
    let(:params) do
      {
        'name' => 'req',
        'groupId' => '975a79f94b84452ea1c920325967a33c',
        'sourceServerId' => 'CENTOS-6-64-TEMPLATE',
        'cpu' => 1,
        'memoryGB' => 1,
        'type' => 'standard'
      }
    end

    context 'with valid params', with_vcr('client/create_server/valid') do
      subject(:creation_response) { client.create_server(params) }

      it_behaves_like 'async operation'

      it 'returns link to the queued server' do
        expect(creation_response).to include('resource')
      end

      it 'creates resource with all passed parameters' do
        creation_response

        expect(WebMock).to have_requested(:post, %r{/v2/servers/#{client.account}})
          .with(:body => params)
      end
    end
  end

  describe '#delete_server' do
    context 'with valid params', with_vcr('client/delete_server/valid') do
      subject(:deletion_response) { client.delete_server(id) }

      let(:id) { 'ca1altdreq17' }

      it_behaves_like 'async operation'

      it 'deletes resource' do
        deletion_response
        expect(WebMock).to have_requested(:delete, %r{/v2/servers/#{client.account}/#{id}})
      end
    end
  end

  describe '#reset_server' do
    context 'with valid params', with_vcr('client/reset_server/valid') do
      subject(:reset_response) { client.reset_server(id) }

      let(:id) { 'ca1altdtest47' }

      it_behaves_like 'async operation'

      it 'resets the server' do
        reset_response
        expect(WebMock).to have_requested(:post, %r{/v2/operations/#{client.account}/servers/reset})
          .with(:body => [id].to_json)
      end
    end
  end

  describe '#reboot_server' do
    context 'with valid params', with_vcr('client/reboot_server/valid') do
      subject(:reboot_response) { client.reboot_server(id) }

      let(:id) { 'ca1altdtest47' }

      it_behaves_like 'async operation'

      it 'reboots the server' do
        reboot_response
        expect(WebMock).to have_requested(:post, %r{/v2/operations/#{client.account}/servers/reboot})
          .with(:body => [id].to_json)
      end
    end
  end

  describe '#power_off_server' do
    context 'with valid params', with_vcr('client/power_off_server/valid') do
      subject(:power_on_response) { client.power_off_server(id) }

      let(:id) { 'ca1altdtest47' }

      it_behaves_like 'async operation'

      it 'turns server power off' do
        power_on_response
        expect(WebMock).to have_requested(:post, %r{/v2/operations/#{client.account}/servers/powerOff})
          .with(:body => [id].to_json)
      end
    end
  end

  describe '#power_on_server' do
    context 'with valid params', with_vcr('client/power_on_server/valid') do
      subject(:power_on_response) { client.power_on_server(id) }

      let(:id) { 'ca1altdtest47' }

      it_behaves_like 'async operation'

      it 'turns server power on' do
        power_on_response
        expect(WebMock).to have_requested(:post, %r{/v2/operations/#{client.account}/servers/powerOn})
          .with(:body => [id].to_json)
      end
    end
  end

  describe '#create_ip_address' do
    context 'with valid params', with_vcr('client/create_ip_address/valid') do
      subject(:ip_assignment_response) { client.create_ip_address(server_id, 'ports' => ports) }

      let(:server_id) { 'ca1altdtest34' }

      let(:ports) do
        [{ 'protocol' => 'tcp', 'port' => 23 }]
      end

      it_behaves_like 'async operation'

      it 'passes specified ports' do
        ip_assignment_response

        creation_url = %r{/v2/servers/#{client.account}/#{server_id}/publicIPAddresses}

        expect(WebMock).to have_requested(:post, creation_url)
          .with(:body => { 'ports' => ports })
      end
    end
  end

  describe '#delete_ip_address' do
    context 'with valid params', with_vcr('client/delete_ip_address/valid') do
      subject(:ip_removal_response) { client.delete_ip_address(server_id, ip_string) }

      let(:server_id) { 'ca1altdtest50' }
      let(:ip_string) { '65.39.180.226' }

      it_behaves_like 'async operation'

      it 'deletes specified IP record' do
        ip_removal_response

        url = %r{/v2/servers/#{client.account}/#{server_id}/publicIPAddresses/#{Regexp.quote(ip_string)}}

        expect(WebMock).to have_requested(:delete, url)
      end
    end
  end

  describe '#list_ip_addresses' do
    context 'when server is specified', with_vcr('client/list_ip_addresses/valid') do
      let(:server_id) { 'ca1altdtest51' }

      it 'returns an Array' do
        expect(client.list_ip_addresses('ca1altdtest51')).to be_an(Array)
      end

      it 'queries server for IP address details' do
        url = %r{/v2/servers/#{client.account}/#{server_id}\?}i

        client.list_ip_addresses(server_id)

        expect(WebMock).to have_requested(:get, url)
      end

      it 'makes a separate call to get complete IP address data' do
        url = %r{/v2/servers/#{client.account}/#{server_id}/publicIPAddresses/.+}i

        client.list_ip_addresses(server_id)

        expect(WebMock).to have_requested(:get, url)
      end

      it 'sets an ID property on returned records' do
        expect(client.list_ip_addresses(server_id)).to all(include('id'))
      end
    end

    context 'when server is not specified', with_vcr('client/list_ip_addresses/without_server') do
      it 'fails' do
        expect { client.list_templates }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#list_datacenters' do
    context 'with cloud success', with_vcr('client/list_datacenters/success') do
      it 'returns a list of datatacenters' do
        expect(subject.list_datacenters).to be_an(Array)
      end
    end
  end

  describe '#show_datacenter' do
    context 'with group links option', with_vcr('client/show_datacenter/with_groups') do
      it 'returns datacenters with group links' do
        response = subject.show_datacenter('ca1', true)
        group_link = response['links'].detect { |link| link['rel'] == 'group' }
        expect(group_link).to be_an(Hash)
      end
    end

    context 'without group links option', with_vcr('client/show_datacenter/without_groups') do
      it 'returns datacenters without group links' do
        response = subject.show_datacenter('ca1', false)
        group_link = response['links'].detect { |link| link['rel'] == 'group' }
        expect(group_link).to be_nil
      end
    end
  end

  describe '#show_group' do
    context 'with cloud success', with_vcr('client/show_group/success') do
      it 'returns groups details withing sub groups and their details' do
        response = subject.show_group('5ffda89a8ce6444baa8d28b9d1581e6d')
        expect(response['id']).to eq('5ffda89a8ce6444baa8d28b9d1581e6d')
      end
    end
  end

  describe '#list_groups' do
    context 'within datacenter', with_vcr('client/list_groups/success') do
      it 'returns a list of datacenters groups' do
        response = subject.list_groups('ca1')
        expect(response).to be_an(Array)
        expect(response.map { |group| group['groups'] }).to all(be_nil)
      end
    end
  end

  describe '#list_templates' do
    context 'when datacenter specified' do
      context 'and exists', with_vcr('client/list_templates/datacenter_exists') do
        let(:datacenter_id) { 'ca1' }

        it 'returns an Array' do
          expect(client.list_templates('ca1')).to be_an(Array)
        end
      end

      context 'and does not exist', with_vcr('client/list_templates/datacenter_does_not_exist') do
        let(:datacenter_id) { 'does-not-exist' }

        it 'fails' do
          expect { client.list_templates(datacenter_id) }.to raise_error(Clc::CloudExceptions::Error)
        end
      end
    end

    context 'when datacenter is not specified', with_vcr('client/list_templates/without_datacenter') do
      it 'fails' do
        expect { client.list_templates }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#show_operation' do
    context 'with cloud success', with_vcr('client/show_operation/success') do
      subject(:operation_response) { client.show_operation(operation_id) }

      let(:operation_id) { 'ca1-41998' }

      it { is_expected.to be_a(Hash) }
      it { is_expected.to include('status') }

      it 'gets specified operation by its resource link' do
        operation_response

        operation_url = %r{/v2/operations/#{client.account}/status/#{operation_id}}

        expect(WebMock).to have_requested(:get, operation_url)
      end
    end
  end

  describe '#wait_for' do
    subject(:operation_result) { client.wait_for(operation_id) }

    let(:operation_id) { 'ca1-41998' }

    context 'with completed operation', with_vcr('client/wait_for/completed') do
      context 'considering overall execution' do
        it 'does not fail' do
          expect { operation_result }.to_not raise_error
        end

        it { is_expected.to be true }
      end

      context 'considering passed block' do
        subject(:wait_for) { ->(block) { client.wait_for(operation_id, &block) } }

        it { is_expected.to yield_control.once }
      end
    end

    context 'with pending operation', with_vcr('client/wait_for/pending') do
      before(:each) { allow(client).to receive(:sleep) }

      context 'considering overall execution' do
        it 'does not fail' do
          expect { operation_result }.to_not raise_error
        end

        it { is_expected.to be true }
      end

      context 'considering passed block' do
        subject(:wait_for) { ->(block) { client.wait_for(operation_id, &block) } }

        it 'yields until operation is complete' do
          expect(wait_for).to yield_control.twice
        end
      end

      context 'considering timeouts' do
        subject(:wait_for) { -> { client.wait_for(operation_id, max_seconds) } }

        let(:max_seconds) { 0 }

        it { is_expected.to raise_error(/takes too much time to complete/) }
      end
    end

    context 'with failed operation', with_vcr('client/wait_for/failed') do
      subject(:wait_for) { -> { client.wait_for(operation_id) } }

      it { is_expected.to raise_error(/operation failed/i) }
    end

    context 'with unrecognized operation status', with_vcr('client/wait_for/unrecognized') do
      subject(:wait_for) { -> { client.wait_for(operation_id) } }

      it { is_expected.to raise_error(/operation status unknown/i) }
    end
  end
end
