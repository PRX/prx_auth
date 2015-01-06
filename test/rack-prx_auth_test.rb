require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'
require 'minitest/stub_any_instance'
require 'rack/prx_auth'
require 'lumberjack' rescue nil

describe Rack::PrxAuth do
  let(:app) { Proc.new {|env| env } }
  let(:prxauth) { Rack::PrxAuth.new(app) }
  let(:fake_token) { 'afawefawefawefawegstgnsrtiohnlijblublwjnvrtoign'}
  let(:env) { {'HTTP_AUTHORIZATION' => 'Bearer ' + fake_token } }
  let(:claims) { {'sub'=>3, 'exp'=>3600, 'iat'=>Time.now.to_i, 'token_type'=>'bearer', 'scope'=>nil, 'iss'=>'id.prx.org'} }

  describe '#call' do
    it 'does nothing if there is no authorization header' do
      env = {}

      prxauth.call(env).must_equal env
    end

    it 'does nothing if the token is from another issuer' do
      claims['iss'] = 'auth.elsewhere.org'

      JSON::JWT.stub(:decode, claims) do
        prxauth.call(env.clone).must_equal env
      end
    end

    it 'does nothing if token is invalid' do
      prxauth.call(env.clone).must_equal env
    end

    it 'returns 401 if verification fails' do
      JSON::JWT.stub(:decode, claims) do
        prxauth.stub(:valid?, false) do
          prxauth.call(env).must_equal Rack::PrxAuth::INVALID_TOKEN
        end
      end
    end

    it 'returns 401 if access token has expired' do
      JSON::JWT.stub(:decode, claims) do
        prxauth.stub(:expired?, true) do
          prxauth.call(env).must_equal Rack::PrxAuth::INVALID_TOKEN
        end
      end
    end

    it 'attaches claims to request params if verification passes' do
      JSON::JWT.stub(:decode, claims) do
        prxauth.call(env)['prx.auth'].tap do |token|
          token.must_be_instance_of Rack::PrxAuth::TokenData
          token.attributes.must_equal claims
          token.user_id.must_equal claims['sub']
        end
      end
    end
  end

  describe '#token_expired?' do
    it 'returns true if token is expired' do
      claims['iat'] = Time.now.to_i - 4000

      prxauth.send(:expired?, claims).must_equal true
    end

    it 'returns false if it is valid' do
      prxauth.send(:expired?, claims).must_equal false
    end
  end

  describe 'initialize' do
    it 'takes a certificate location as an option' do
      loc = nil
      Rack::PrxAuth::Certificate.stub(:new, Proc.new{|l| loc = l}) do
        Rack::PrxAuth.new(app, cert_location: :location)
        loc.must_equal :location
      end
    end
  end

  describe Rack::PrxAuth::Certificate do
    let(:subject) { Rack::PrxAuth::Certificate.new }
    let(:certificate) { subject }

    describe '#initialize' do
      it 'allows setting the location of the certificates' do
        cert = Rack::PrxAuth::Certificate.new('http://example.com')
        cert.cert_location.must_equal URI('http://example.com')
      end

      it 'defaults to DEFAULT_CERT_LOC' do
        cert = Rack::PrxAuth::Certificate.new
        cert.cert_location.must_equal Rack::PrxAuth::Certificate::DEFAULT_CERT_LOC
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
        JSON::JWT.stub(:decode, Proc.new {|t, k|
          raise JSON::JWT::VerificationFailed }) do
          certificate.wont_be :valid?, :token
        end
      end

      it 'returns true if verification passes' do
        JSON::JWT.stub(:decode, {}) do
          certificate.must_be :valid?, :token
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
end
