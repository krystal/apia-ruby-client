# frozen_string_literal: true

require_relative './lib/apia_client/version'

Gem::Specification.new do |s|
  s.name          = 'apia-client'
  s.description   = 'A client library for talking to any Apia API.'
  s.summary       = s.description
  s.homepage      = 'https://github.com/apiaframework/apia-ruby-client'
  s.version       = ApiaClient::VERSION
  s.licenses      = ['MIT']
  s.files         = Dir.glob('VERSION') + Dir.glob('{lib}/**/*')
  s.require_paths = ['lib']
  s.authors       = ['Adam Cooke']
  s.email         = ['adam@k.io']
  s.add_runtime_dependency 'apia-schema-parser', '>= 1.0.0'
  s.add_runtime_dependency 'json'
  s.required_ruby_version = '>= 2.5'
end
