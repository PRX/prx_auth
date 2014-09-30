# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack/prxauth/version'

Gem::Specification.new do |spec|
  spec.name          = "rack-prxauth"
  spec.version       = Rack::Prxauth::VERSION
  spec.authors       = ["Eve Asher"]
  spec.email         = ["eve@prx.org"]
  spec.summary       = %q{Rack middleware that verifies and decodes a JWT token and attaches the token's claims to env.}
  spec.description   = %q{Specific to PRX. Will ignore tokens that were not issued by PRX.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-minitest"

  spec.add_dependency "rack"
  spec.add_dependency "json"
  spec.add_dependency "json-jwt"
end
