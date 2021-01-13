require 'json/jwt'

module Rack
  class PrxAuth
    class AuthValidator

      attr_reader :issuer, :claims, :token

      def initialize(token, certificate, issuer)
        @token = token
        @certificate = certificate
        @issuer = issuer
      end

      def valid?
        valid_token_format? && !expired? && @certificate.valid?(token)
      end

      def claims
        @claims ||= decode_token
      end

      def valid_token_format?
        decode_token.present?
      end

      def decode_token
        return {} if token.nil?

        begin
          JSON::JWT.decode(token, :skip_verification)
        rescue JSON::JWT::InvalidFormat
          {}
        end
      end

      def expired?
        now = Time.now.to_i - 30 # 30 second clock jitter allowance
        if claims['iat'] <= claims['exp']
          now > claims['exp']
        else
          now > (claims['iat'] + claims['exp'])
        end
      end

      def token_issuer_matches?
        claims['iss'] == @issuer
      end
    end
  end
end
