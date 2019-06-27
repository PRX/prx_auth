require 'test_helper'

describe Rack::PrxAuth do
  let(:app) { Proc.new {|env| env } }
  let(:prxauth) { Rack::PrxAuth.new(app) }
  let(:fake_token) { 'afawefawefawefawegstgnsrtiohnlijblublwjnvrtoign'}
  let(:env) { {'HTTP_AUTHORIZATION' => 'Bearer ' + fake_token } }
  let(:claims) { {'sub'=>3, 'exp'=>3600, 'iat'=>Time.now.to_i, 'token_type'=>'bearer', 'scope'=>nil, 'iss'=>'id.prx.org'} }

  describe '#call' do
    it 'does nothing if there is no authorization header' do
      env = {}

      prxauth.call(env.clone).must_equal env
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

    it 'does nothing if the token is nil' do
      env = {"HTTP_AUTHORIZATION"=>"Bearer "}
      prxauth.call(env).must_equal env
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
      prxauth.stub(:decode_token, claims) do
        prxauth.stub(:valid?, true) do
          prxauth.call(env)['prx.auth'].tap do |token|
            token.must_be_instance_of Rack::PrxAuth::TokenData
            token.attributes.must_equal claims
            token.user_id.must_equal claims['sub']
          end
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

  describe '#decode_token' do
    it 'should return an empty result for a nil token' do
      prxauth.send(:decode_token, nil).must_equal({})
    end

    it 'should return an empty result for an empty token' do
      prxauth.send(:decode_token, {}).must_equal({})
    end

    it 'should return an empty result for a malformed token' do
      prxauth.send(:decode_token, 'asdfsadfsad').must_equal({})
    end
  end
end
