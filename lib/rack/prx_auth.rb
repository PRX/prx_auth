require 'json/jwt'
require 'rack/prx_auth/certificate'
require 'rack/prx_auth/token_data'
require 'rack/prx_auth/auth_validator'
require 'prx_auth'

module Rack
  class PrxAuth
    INVALID_TOKEN = [
      401, {'Content-Type' => 'application/json'},
      [{status: 401, error: 'Invalid JSON Web Token'}.to_json]
    ]

    DEFAULT_ISS = 'id.prx.org'

    attr_reader :issuer

    def initialize(app, options = {})
      @app = app
      @certificate = Certificate.new(options[:cert_location])
      @issuer = options[:issuer] || DEFAULT_ISS
    end

    def build_auth_validator(token)
      AuthValidator.new(token, @certificate, @issuer)
    end

    def call(env)
      return @app.call(env) unless env['HTTP_AUTHORIZATION']

      token = env['HTTP_AUTHORIZATION'].split[1]

      auth_validator = build_auth_validator(token)

      return @app.call(env) unless should_validate_token?(auth_validator)

      if auth_validator.valid?
        env['prx.auth'] = TokenData.new(auth_validator.claims)
        @app.call(env)
      else
        INVALID_TOKEN
      end
    end

    private

    def should_validate_token?(auth_validator)
      auth_validator.token_issuer_matches?
    end
  end
end
