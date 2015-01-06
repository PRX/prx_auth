require 'json/jwt'
require 'rack/prx_auth/version'
require 'rack/prx_auth/certificate'
require 'rack/prx_auth/token_data'
require 'rack/prx_auth/railtie' if defined?(Rails)

module Rack
  class PrxAuth
    INVALID_TOKEN = [
      401, {'Content-Type' => 'application/json'},
      [{status: 401, error: 'Invalid JSON Web Token'}.to_json]
    ]

    DEFAULT_ISS = 'id.prx.org'

    attr_reader :public_key, :issuer

    def initialize(app, options = {})
      @app = app
      @certificate = Certificate.new(options[:cert_location])
      @issuer = options[:issuer] || DEFAULT_ISS
    end

    def call(env)
      return @app.call(env) unless env['HTTP_AUTHORIZATION']

      token = env['HTTP_AUTHORIZATION'].split[1]
      claims = decode_token(token)

      return @app.call(env) unless should_validate_token?(claims)

      if valid?(claims, token)
        env['prx.auth'] = TokenData.new(claims)
        @app.call(env)
      else
        INVALID_TOKEN
      end
    end

    private

    def valid?(claims, token)
      !expired?(claims) && @certificate.valid?(token)
    end

    def decode_token(token)
      begin
        JSON::JWT.decode(token, :skip_verification)
      rescue JSON::JWT::InvalidFormat
        {}
      end
    end

    def expired?(claims)
      Time.now.to_i > (claims['iat'] + claims['exp'])
    end

    def should_validate_token?(claims)
      claims['iss'] == @issuer
    end
  end
end
