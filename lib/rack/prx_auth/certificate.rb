require "json/jwt"
require "net/http"

module Rack
  class PrxAuth
    class Certificate
      EXPIRES_IN = 43200
      DEFAULT_CERT_LOC = URI("https://id.prx.org/api/v1/certs")

      attr_reader :cert_location

      def initialize(cert_uri = nil)
        @cert_location = cert_uri.nil? ? DEFAULT_CERT_LOC : URI(cert_uri)
        @certificate = nil
      end

      def valid?(token)
        JSON::JWT.decode(token, public_key)
      rescue JSON::JWT::VerificationFailed
        false
      else
        true
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
        certs = JSON.parse(fetch_http)
        cert_string = certs["certificates"].values[0]
        @refresh_at = Time.now.to_i + EXPIRES_IN
        OpenSSL::X509::Certificate.new(cert_string)
      end

      def fetch_http(retries = 2, sleep_seconds = 0.5)
        host = cert_location.host
        port = cert_location.port
        path = cert_location.path
        ssl = cert_location.scheme == "https"
        res = Net::HTTP.start(host, port, use_ssl: ssl) { |http| http.request_get(path) }

        if res.is_a?(Net::HTTPSuccess)
          res.body
        elsif res.code.to_i >= 500 && retries > 0
          sleep sleep_seconds
          fetch_http(retries - 1, sleep_seconds)
        else
          raise "Got #{res.code} from #{cert_location}"
        end
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
