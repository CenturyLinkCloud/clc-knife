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

  context 'when cloud fails with bad request error', with_vcr('cloud_exceptions/handler/bad_request') do
    it 'raises BadRequest exception' do
      expect { client.list_datacenters }.to raise_error(Clc::CloudExceptions::BadRequest)
    end
  end

  context 'when cloud fails with unauthorized error', with_vcr('cloud_exceptions/handler/unauthorized') do
    it 'raises Unauthorized exception' do
      expect { client.list_datacenters }.to raise_error(Clc::CloudExceptions::Unauthorized)
    end
  end

  context 'when cloud fails with forbidden error', with_vcr('cloud_exceptions/handler/forbidden') do
    it 'raises Forbidden exception' do
      expect { client.list_datacenters }.to raise_error(Clc::CloudExceptions::Forbidden)
    end
  end

  context 'when cloud fails with unknown error', with_vcr('cloud_exceptions/handler/unknown_error') do
    it 'raises UnknownError exception' do
      expect { client.list_datacenters }.to raise_error(Clc::CloudExceptions::UnknownError)
    end
  end

  context 'when cloud fails with Method Not Allowed error', with_vcr('cloud_exceptions/handler/method_not_allowed') do
    it 'raises MethodNotAllowed exception' do
      expect { client.list_datacenters }.to raise_error(Clc::CloudExceptions::MethodNotAllowed)
    end
  end
end
