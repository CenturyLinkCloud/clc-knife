# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'knife-clc/version'

Gem::Specification.new do |spec|
  spec.name          = 'knife-clc'
  spec.version       = Knife::Clc::VERSION
  spec.authors       = ['Alexander Sologub']
  spec.email         = ['alexander.sologub@rightscale.com']

  spec.summary       = %q{TODO: Write a short summary, because Rubygems requires one.}
  spec.description   = %q{TODO: Write a longer description or delete this line.}
  spec.homepage      = 'TODO: Put your gem\'s website or public repo URL here.'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'faraday', '~> 0.9.2'
  spec.add_dependency 'faraday_middleware', '~> 0.10.0'
  spec.add_dependency 'formatador', '~> 0.2.5'
  spec.add_dependency 'hirb', '~> 0.7.3'

  spec.add_development_dependency 'webmock', '~> 1.22.3'
  spec.add_development_dependency 'rubocop', '~> 0.34.2'
  spec.add_development_dependency 'simplecov', '~> 0.10.0'
  spec.add_development_dependency 'coveralls', '~> 0.8.9'
  spec.add_development_dependency 'pry-byebug', '~> 3.3.0'
  spec.add_development_dependency 'rspec', '~> 3.4.0'
  spec.add_development_dependency 'vcr', '~> 3.0.0'
  spec.add_development_dependency 'bundler', '~> 1.9'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'chef', '~> 12.5.1'
end
