require 'rack/request'
require 'json/jwt'
require 'rack/prx_auth/version'

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

        if verified?(token) && !token_expired?(claims) && !cert_expired?(@public_key.certificate)
          env['prx.auth'] = claims
          @app.call(env)
        else
          [401, {'Content-Type' => 'application/json'}, [{status: 401, error: 'Invalid JSON Web Token'}.to_json]]
        end
      else
        @app.call(env)
      end
    end

    def verified?(token)
      begin
        JSON::JWT.decode(token, @public_key.key)
      rescue JSON::JWT::VerificationFailed
        false
      else
        true
      end
    end

    def cert_expired?(certificate)
      certificate.not_after < Time.now
    end

    def token_expired?(claims)
      Time.now.to_i > (claims['iat'] + claims['exp'])
    end



    class PublicKey
      EXPIRES_IN = 43200
      AUTH_URI = URI('https://auth.prx.org/api/v1/certs')

      attr_reader :certificate

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
        @certificate = get_certificate
        @key = @certificate.public_key
      end

      def get_certificate
        certs = JSON.parse(Net::HTTP.get(AUTH_URI))
        cert_string = certs['certificates'].values[0]
        OpenSSL::X509::Certificate.new(cert_string)
      end

      def key
        refresh_key
        @key
      end
    end
  end
end

