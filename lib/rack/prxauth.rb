require 'rack/request'
require 'json/jwt'
require 'rack/prxauth/version'
require 'pry'

module Rack
  class PrxAuth
    attr_reader :public_key

    def initialize(app)
      @app = app
      @public_key = PublicKey.new
    end

    def call(env)
      if env['HTTP_AUTHORIZATION'] =~ /\ABearer/
        token = env['HTTP_AUTHORIZATION'].split[1]
        claims = JSON::JWT.decode(token, :skip_verification)

        @app.call(env) unless claims['iss'] == 'auth.prx.org'

        if verify(token)
          env['prx.auth'] = claims
          @app.call(env)
        else
          [401, {'Content-Type' => 'application/json'}, [{status: 401, error: 'Invalid JSON Web Token'}.to_json]]
        end
      else
        @app.call(env)
      end
    end

    def verify(token)
      begin
        JSON::JWT.decode(token, @public_key)
      rescue JSON::JWT::VerificationFailed
        false
      else
        true
      end
    end

    class PublicKey
      EXPIRES_IN = 43200
      AUTH_URI = URI('https://auth.prx.org/api/v1/certs')

      def initialize
        @created_at = Time.now
        get_key
      end

      def refresh_key
        if Time.now > @created_at + EXPIRES_IN
          get_key
        end
      end

      def get_key
        certs = JSON.parse(Net::HTTP.get(AUTH_URI))
        cert_string = certs['certificates'].values[0]
        certificate = OpenSSL::X509::Certificate.new(cert_string)
        @key = certificate.public_key
      end

      def key
        refresh_key
        @key
      end
    end
  end
end

