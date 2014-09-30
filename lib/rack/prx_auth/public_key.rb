module Rack
  class PrxAuth
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
