require 'json/jwt'

module Rack
  class PrxAuth
    class AuthValidator

      attr_reader :issuer, :token

      def initialize(token, certificate = nil, issuer = nil)
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
        (time_to_live + 30) <= 0 # 30 second clock jitter allowance
      end

      def time_to_live
        now = Time.now.to_i
        if claims['exp'].nil?
          0
        elsif claims['iat'].nil? || claims['iat'] <= claims['exp']
          claims['exp'] - now
        else
          # malformed - exp is a num-seconds offset from issued-at-time
          (claims['iat'] + claims['exp']) - now
        end
      end

      def token_issuer_matches?
        claims['iss'] == @issuer
      end
    end
  end
end
