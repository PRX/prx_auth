require "test_helper"

describe Rack::PrxAuth::Certificate do
  let(:cert_uri) { "http://example.com/certs" }
  let(:subject) { Rack::PrxAuth::Certificate.new(cert_uri) }
  let(:certificate) { subject }

  describe "#initialize" do
    it "allows setting the location of the certificates" do
      cert = Rack::PrxAuth::Certificate.new("http://example.com")
      assert cert.cert_location == URI("http://example.com")
    end

    it "defaults to DEFAULT_CERT_LOC" do
      cert = Rack::PrxAuth::Certificate.new
      assert cert.cert_location == Rack::PrxAuth::Certificate::DEFAULT_CERT_LOC
    end
  end

  describe "#valid?" do
    it "validates the token with the public key" do
      token, key = nil, nil
      certificate.stub(:public_key, :public_key) do
        JSON::JWT.stub(:decode, proc { |t, k| token, key = t, k }) do
          certificate.valid?(:token)
        end
      end

      assert token == :token
      assert key == :public_key
    end

    it "returns false if verification fails" do
      JSON::JWT.stub(:decode, proc do |t, k|
        raise JSON::JWT::VerificationFailed
      end) do
        certificate.stub(:public_key, :foo) do
          assert !certificate.valid?(:token)
        end
      end
    end

    it "returns true if verification passes" do
      JSON::JWT.stub(:decode, {}) do
        certificate.stub(:public_key, :foo) do
          assert certificate.valid?(:token)
        end
      end
    end
  end

  describe "#certificate" do
    it "calls fetch if unprimed" do
      def certificate.fetch
        :sigil
      end

      assert certificate.send(:certificate) == :sigil
    end
  end

  describe "#public_key" do
    it "pulls from the certificate" do
      certificate.stub(:certificate, Struct.new(:public_key).new(:key)) do
        assert certificate.send(:public_key) == :key
      end
    end
  end

  describe "#fetch" do
    let(:fake_json) { "{\"certificates\":{\"asdf\":\"the-cert-content\"}}" }

    it "pulls from `#cert_location`" do
      stub_request(:get, cert_uri).to_return(body: fake_json)

      OpenSSL::X509::Certificate.stub(:new, ->(x) { x }) do
        assert_equal "the-cert-content", certificate.send(:fetch)
      end
    end

    it "sets the expiration value" do
      stub_request(:get, cert_uri).to_return(body: fake_json)

      OpenSSL::X509::Certificate.stub(:new, ->(_) { Struct.new(:not_after).new(Time.now + 10000) }) do
        certificate.send :certificate
        assert !certificate.send(:needs_refresh?)
      end
    end

    it "retries 5XX errors" do
      stub_request(:get, cert_uri)
        .to_return(status: 502)
        .to_return(status: 504)
        .to_return(status: 200, body: TEST_CERT_JSON)

      assert_instance_of OpenSSL::X509::Certificate, certificate.send(:fetch)
    end

    it "raises other errors" do
      stub_request(:get, cert_uri)
        .to_return(status: 501)
        .to_return(status: 502)
        .to_return(status: 503)
        .to_return(status: 504)

      err = assert_raises(RuntimeError) { certificate.send(:fetch) }
      assert_equal "Got 503 from #{cert_uri}", err.message
    end

    it "runs out of retries" do
      stub_request(:get, cert_uri).to_return(status: 502).to_return(status: 401)

      err = assert_raises(RuntimeError) { certificate.send(:fetch) }
      assert_equal "Got 401 from #{cert_uri}", err.message
    end
  end

  describe "#expired?" do
    let(:stub_cert) { Struct.new(:not_after).new(Time.now + 10000) }
    before(:each) do
      certificate.instance_variable_set :@certificate, stub_cert
    end

    it "is false when the certificate is not expired" do
      assert !certificate.send(:expired?)
    end

    it "is true when the certificate is expired" do
      stub_cert.not_after = Time.now - 500
      assert certificate.send(:expired?)
    end
  end

  describe "#needs_refresh?" do
    def refresh_at=(time)
      certificate.instance_variable_set :@refresh_at, time
    end

    it "is true if certificate is expired" do
      certificate.stub(:expired?, true) do
        assert certificate.send(:needs_refresh?)
      end
    end

    it "is true if we are past refresh value" do
      self.refresh_at = Time.now.to_i - 1000
      certificate.stub(:expired?, false) do
        assert certificate.send(:needs_refresh?)
      end
    end

    it "is false if certificate is not expired and refresh is in the future" do
      self.refresh_at = Time.now.to_i + 10000
      certificate.stub(:expired?, false) do
        assert !certificate.send(:needs_refresh?)
      end
    end
  end
end
