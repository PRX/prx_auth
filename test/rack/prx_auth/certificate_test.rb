require 'test_helper'

describe Rack::PrxAuth::Certificate do
  let(:subject) { Rack::PrxAuth::Certificate.new }
  let(:certificate) { subject }

  describe '#initialize' do
    it 'allows setting the location of the certificates' do
      cert = Rack::PrxAuth::Certificate.new('http://example.com')
      cert.cert_location.must_equal URI('http://example.com')
    end

    it 'defaults to DEFAULT_CERT_LOC' do
      certificate.cert_location.must_equal Rack::PrxAuth::Certificate::DEFAULT_CERT_LOC
    end
  end

  describe '#valid?' do
    it 'validates the token with the public key' do
      token, key = nil, nil
      certificate.stub(:public_key, :public_key) do
        JSON::JWT.stub(:decode, Proc.new {|t, k| token, key = t, k }) do
          certificate.valid?(:token)
        end
      end

      token.must_equal :token
      key.must_equal :public_key
    end

    it 'returns false if verification fails' do
      JSON::JWT.stub(:decode, Proc.new do |t, k|
        raise JSON::JWT::VerificationFailed
      end) do
        certificate.stub(:public_key, :foo) do
          certificate.wont_be :valid?, :token
        end
      end
    end

    it 'returns true if verification passes' do
      JSON::JWT.stub(:decode, {}) do
        certificate.stub(:public_key, :foo) do
          certificate.must_be :valid?, :token
        end
      end
    end
  end

  describe '#certificate' do
    it 'calls fetch if unprimed' do
      def certificate.fetch
        :sigil
      end

      certificate.send(:certificate).must_equal :sigil
    end
  end
end
