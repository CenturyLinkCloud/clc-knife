require 'coveralls'
Coveralls.wear!

require 'vcr'
require 'clc'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :faraday
  c.configure_rspec_metadata!
  c.preserve_exact_body_bytes { true }

  c.filter_sensitive_data('<CLC_PASSWORD>') { ENV['CLC_PASSWORD'] }
  c.filter_sensitive_data('<CLC_USERNAME>') { ENV['CLC_USERNAME'] }
  c.filter_sensitive_data('<CLC_BEARER_TOKEN>') do |interaction|
    interaction.request.headers.delete('Authorization')
  end

  c.before_record do |interaction|
    if interaction.request.uri == 'https://api.ctl.io/v2/authentication/login'
      interaction.response.body.gsub!(/bearerToken":".{516}/, "bearerToken\":\"<CLC_BEARER_TOKEN>")
    end
  end
end

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
