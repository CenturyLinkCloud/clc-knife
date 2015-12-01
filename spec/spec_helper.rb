require 'simplecov'
require 'coveralls'

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]

SimpleCov.start do
  add_filter 'spec'
end

require 'vcr'
require 'webmock/rspec'
require 'clc'
require 'pry'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!

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

  c.before_record(:pooling) do |interaction|
    if interaction.request.uri =~ /\/v2\/operations/
      status = JSON.parse(interaction.response.body)['status']
      interaction.ignore! unless ['failed', 'unknown', 'succeeded'].include? status
    end
  end
end

module VCRHelpers
  def with_vcr(name, tag = nil)
    { :vcr => { :cassette_name => name } }.tap do |opts|
      opts[:vcr][:tag] = tag if tag
    end
  end
end

RSpec.configure do |config|
  config.extend VCRHelpers

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
end
