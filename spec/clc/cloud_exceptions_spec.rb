describe Clc::CloudExceptions::Handler do
  let(:client) { Clc::Client.new }

  context 'when cloud does not fail', with_vcr('cloud_exceptions/handler/success') do
    it 'does not raise an error' do
      client.list_datacenters
    end
  end

  context 'when cloud cant find resource', with_vcr('cloud_exceptions/handler/not_found') do
    it 'raises NotFound exception' do
      expect { client.show_datacenter('not-real') }.to raise_error(Clc::CloudExceptions::NotFound)
    end
  end

  context 'when cloud fails with internal error', with_vcr('cloud_exceptions/handler/internal_error') do
    it 'raises InternalError exception' do
      expect { client.list_datacenters }.to raise_error(Clc::CloudExceptions::InternalServerError)
    end
  end
end
