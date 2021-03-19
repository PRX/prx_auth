require 'json/jwt'
require 'net/http'

module Rack
  class PrxAuth
    class Certificate
      EXPIRES_IN = 43200
      DEFAULT_CERT_LOC = URI('https://id.prx.org/api/v1/certs')

      attr_reader :cert_location

      def initialize(cert_uri = nil)
        @cert_location = cert_uri.nil? ? DEFAULT_CERT_LOC : URI(cert_uri)
        @certificate = nil
      end

      def valid?(token)
        begin
          JSON::JWT.decode(token, public_key)
        rescue JSON::JWT::VerificationFailed
          false
        else
          true
        end
      end

      private

      def public_key
        certificate.public_key
      end

      def certificate
        if @certificate.nil? || needs_refresh?
          @certificate = fetch
        end
        @certificate
      end

      def fetch
        certs = JSON.parse(Net::HTTP.get(cert_location))
        cert_string = certs['certificates'].values[0]
        @refresh_at = Time.now.to_i + EXPIRES_IN
        OpenSSL::X509::Certificate.new(cert_string)
      end

      def needs_refresh?
        expired? || @refresh_at <= Time.now.to_i
      end

      def expired?
        @certificate.not_after < Time.now
      end
    end
  end
end
