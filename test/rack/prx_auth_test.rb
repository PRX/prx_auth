require 'test_helper'

describe Rack::PrxAuth do
  let(:app) { Proc.new {|env| env } }
  let(:prxauth) { Rack::PrxAuth.new(app) }
  let(:fake_token) { 'afawefawefawefawegstgnsrtiohnlijblublwjnvrtoign'}
  let(:env) { {'HTTP_AUTHORIZATION' => 'Bearer ' + fake_token } }
  let(:iat) { Time.now.to_i }
  let(:exp) { 3600 }
  let(:claims) { {'sub'=>3, 'exp'=>exp, 'iat'=>iat, 'token_type'=>'bearer', 'scope'=>nil, 'iss'=>'id.prx.org'} }

  describe '#call' do
    it 'does nothing if there is no authorization header' do
      env = {}

      assert prxauth.call(env.clone) == env
    end

    it 'does nothing if the token is from another issuer' do
      claims['iss'] = 'auth.elsewhere.org'

      JSON::JWT.stub(:decode, claims) do
        assert prxauth.call(env.clone) == env
      end
    end

    it 'does nothing if token is invalid' do
      assert prxauth.call(env.clone) == env
    end

    it 'does nothing if the token is nil' do
      env = { "HTTP_AUTHORIZATION" => "Bearer "}
      assert prxauth.call(env) == env
    end

    it 'returns 401 if verification fails' do
      JSON::JWT.stub(:decode, claims) do
        prxauth.stub(:valid?, false) do
          assert prxauth.call(env) == Rack::PrxAuth::INVALID_TOKEN
        end
      end
    end

    it 'returns 401 if access token has expired' do
      JSON::JWT.stub(:decode, claims) do
        prxauth.stub(:expired?, true) do
          assert prxauth.call(env) == Rack::PrxAuth::INVALID_TOKEN
        end
      end
    end

    it 'attaches claims to request params if verification passes' do
      prxauth.stub(:decode_token, claims) do
        prxauth.stub(:valid?, true) do
          prxauth.call(env)['prx.auth'].tap do |token|
            assert token.instance_of? Rack::PrxAuth::TokenData
            assert token.user_id == claims['sub']
          end
        end
      end
    end
  end

  describe '#expired?' do

    def expired?(claims)
      prxauth.send(:expired?, claims)
    end

    describe 'with a malformed exp' do
      let(:iat) { Time.now.to_i }
      let(:exp) { 3600 }

      it 'is expired if iat + exp are in the past' do
        claims['iat'] -= 3631

        assert expired?(claims)
      end

      it 'is not expired if iat + exp are in the future' do
        claims['iat'] = Time.now.to_i - 3599

        refute expired?(claims)
      end

      it 'allows a 30s clock jitter' do
        claims['iat'] = Time.now.to_i - 3629

        refute expired?(claims)
      end
    end

    describe 'with a corrected exp' do
      let(:iat) { Time.now.to_i - 3600 }
      let(:exp) { Time.now.to_i + 1 }

      it 'is not expired if exp is in the future' do
        refute expired?(claims)
      end

      it 'is expired if exp is in the past (with 30s jitter grace)' do
        claims['exp'] = Time.now.to_i - 31
        assert expired?(claims)
        claims['exp'] = Time.now.to_i - 29
        refute expired?(claims)
      end
    end
  end

  describe 'initialize' do
    it 'takes a certificate location as an option' do
      loc = nil
      Rack::PrxAuth::Certificate.stub(:new, Proc.new{|l| loc = l}) do
        Rack::PrxAuth.new(app, cert_location: :location)
        assert loc == :location
      end
    end
  end

  describe '#decode_token' do
    it 'should return an empty result for a nil token' do
      assert prxauth.send(:decode_token, nil) == {}
    end

    it 'should return an empty result for an empty token' do
      assert prxauth.send(:decode_token, {}) == {}
    end

    it 'should return an empty result for a malformed token' do
      assert prxauth.send(:decode_token, 'asdfsadfsad') == {}
    end
  end
end
