# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'knife-clc/version'

Gem::Specification.new do |spec|
  spec.name          = 'knife-clc'
  spec.version       = Knife::Clc::VERSION
  spec.authors       = ['Alexander Sologub', 'Alexander Kuntsevich']
  spec.email         = ['alexander.sologub@altoros.com', 'aleksandr.kuntsevich@altoros.com']

  spec.summary       = "CenturyLink Cloud for Chef's Knife Command"
  spec.description   = spec.summary
  spec.homepage      = 'https://github.com/CenturyLinkCloud/clc-knife'
  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '~> 0.9.0'
  spec.add_dependency 'faraday_middleware', '~> 0.10.0'
  spec.add_dependency 'hirb', '~> 0.7.0'
  spec.add_dependency 'chef', '~> 12.0'

  spec.add_development_dependency 'webmock', '~> 1.22.3'
  spec.add_development_dependency 'rubocop', '~> 0.34.2'
  spec.add_development_dependency 'simplecov', '~> 0.10.0'
  spec.add_development_dependency 'coveralls', '~> 0.8.9'
  spec.add_development_dependency 'pry-byebug', '~> 3.3.0'
  spec.add_development_dependency 'rspec', '~> 3.4.0'
  spec.add_development_dependency 'vcr', '~> 3.0.0'
  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'
end
