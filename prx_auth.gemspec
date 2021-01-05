# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'prx_auth/version'

Gem::Specification.new do |spec|
  spec.name          = "prx_auth"
  spec.version       = PrxAuth::VERSION
  spec.authors       = ["Eve Asher", "Chris Rhoden"]
  spec.email         = ["eve@prx.org", "carhoden@gmail.com"]
  spec.summary       = %q{Utilites for parsing PRX JWTs and Rack middleware that verifies and attaches the token's claims to env.}
  spec.description   = %q{Specific to PRX. Will ignore tokens that were not issued by PRX.}
  spec.homepage      = "https://github.com/PRX/prx_auth"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^test/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = '>= 2.3'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 12.3.3'
  spec.add_development_dependency 'coveralls', '~> 0'
  spec.add_development_dependency 'guard'
  spec.add_development_dependency 'guard-minitest'

  spec.add_dependency 'rack', '>= 1.5.2'
  spec.add_dependency 'json', '>= 1.8.1'
  spec.add_dependency 'json-jwt', '~> 1.13.0'
end
