module Rack
  class PrxAuth
    class PublicKey
      EXPIRES_IN = 43200

      attr_reader :certificate, :cert_location

      def initialize(cert_location = nil)
        @created_at = Time.now
        @cert_location = URI(cert_location || 'https://auth.prx.org/api/v1/certs')
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
        certs = JSON.parse(Net::HTTP.get(@cert_location))
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
