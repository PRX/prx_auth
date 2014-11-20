require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'
require 'minitest/stub_any_instance'
require 'rack/prx_auth'

describe Rack::PrxAuth do
  let(:app) { Proc.new {|env| env } }
  let(:prxauth) { Rack::PrxAuth.new(app) }
  let(:fake_token) { 'afawefawefawefawegstgnsrtiohnlijblublwjnvrtoign'}
  let(:env) { {'HTTP_AUTHORIZATION' => 'Bearer ' + fake_token } }
  let(:claims) { {'sub'=>3, 'exp'=>3600, 'iat'=>Time.now.to_i, 'token_type'=>'bearer', 'scope'=>nil, 'iss'=>'auth.prx.org'} }

  describe '#call' do
    it 'does nothing if there is no authorization header' do
      env = {}

      prxauth.call(env).must_equal env
    end

    it 'does nothing if the token is from another issuer' do
      claims['iss'] = 'auth.elsewhere.org'

      JSON::JWT.stub(:decode, claims) do
        prxauth.call(env).must_equal env
      end
    end

    it 'does nothing if token is invalid' do
      prxauth.call(env).must_equal env
    end

    it 'returns 401 if verification fails' do
      JSON::JWT.stub(:decode, claims) do
        prxauth.stub(:verified?, false) do
          prxauth.call(env).must_equal [401, {'Content-Type' => 'application/json'}, [{status: 401, error: 'Invalid JSON Web Token'}.to_json]]
        end
      end
    end

    it 'returns 401 if access token has expired' do
      JSON::JWT.stub(:decode, claims) do
        prxauth.stub(:token_expired?, true) do
          prxauth.call(env).must_equal [401, {'Content-Type' => 'application/json'}, [{status: 401, error: 'Invalid JSON Web Token'}.to_json]]
        end
      end
    end

    it 'returns 401 if certificate has expired' do
      JSON::JWT.stub(:decode, claims) do
        prxauth.stub(:cert_expired?, true) do
          prxauth.call(env).must_equal [401, {'Content-Type' => 'application/json'}, [{status: 401, error: 'Invalid JSON Web Token'}.to_json]]
        end
      end
    end

    it 'attaches claims to request params if verification passes' do
      JSON::JWT.stub(:decode, claims) do
        prxauth.call(env)['prx.auth'].must_be_instance_of Rack::PrxAuth::TokenData
        prxauth.call(env)['prx.auth'].attributes.must_equal claims
        prxauth.call(env)['prx.auth'].user_id.must_equal claims['sub']
      end
    end
  end

  describe '#token_expired?' do
    it 'returns true if token is expired' do
      claims['iat'] = Time.now.to_i - 4000

      prxauth.token_expired?(claims).must_equal true
    end

    it 'returns false if it is valid' do
      prxauth.token_expired?(claims).must_equal false
    end
  end

  describe '#cert_expired?' do
    let(:cert) { prxauth.public_key.certificate }

    it 'returns true if cert is expired' do
      cert.stub(:not_after, Time.now - 100000) do
        prxauth.cert_expired?(cert).must_equal true
      end
    end

    it 'returns false if it is valid' do
      cert.stub(:not_after, Time.now + 100000) do
        prxauth.cert_expired?(cert).must_equal false
      end
    end
  end

  describe '#verified?' do
    it 'returns false if error is raised' do
      raise_error = Proc.new { raise JSON::JWT::VerificationFailed }

      JSON::JWT.stub(:decode, raise_error) do
        prxauth.verified?(fake_token).must_equal false
      end
    end

    it 'returns true if no error is raised' do
      JSON::JWT.stub(:decode, claims) do
        prxauth.verified?(fake_token).must_equal true
      end
    end
  end

  describe 'initialize' do
    it 'takes a certificate location as an option' do
      Rack::PrxAuth::PublicKey.stub_any_instance(:get_key, nil) do
        prxauth = Rack::PrxAuth.new(app, cert_location: 'http://www.prx-auth.org/api/v1/certs')
        key = prxauth.public_key
        key.cert_location.host.must_equal 'www.prx-auth.org'
        key.cert_location.path.must_equal '/api/v1/certs'
      end
    end

    it 'uses auth.prx.org if no uri is given' do
      Rack::PrxAuth::PublicKey.stub_any_instance(:get_key, nil) do
        prxauth = Rack::PrxAuth.new(app)
        key = prxauth.public_key
        key.cert_location.host.must_equal 'auth.prx.org'
        key.cert_location.path.must_equal '/api/v1/certs'
      end
    end
  end
end
