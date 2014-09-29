require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'
require_relative '../lib/rack/prxauth'

describe Rack::PrxAuth do
  let(:app) { Proc.new {|env| env } }
  let(:prxauth) { Rack::PrxAuth.new(app) }
  let(:fake_token) { 'afawefawefawefawegstgnsrtiohnlijbl.ublwjnvrtoign'}
  let(:env) { {'HTTP_AUTHORIZATION' => 'Bearer ' + fake_token } }
  let(:claims) { claims = {'sub'=>nil, 'exp'=>3600, 'iat'=>1411668422, 'token_type'=>'bearer', 'scope'=>nil, 'iss'=>'auth.prx.org'} }

  describe '#call' do
    it 'does nothing if there is no authorization header' do
      env = {}

      prxauth.call(env).must_equal env
    end

    it 'does nothing if the token is from another issuer' do
      JSON::JWT.stub(:decode, {'iss'=>'auth.elsewhere.org'}) do
        prxauth.call(env).must_equal env
      end
    end

    it 'returns 401 if verification fails' do
      JSON::JWT.stub(:decode, claims) do
        prxauth.stub(:verify, false) do
          prxauth.call(env).must_equal [401, {'Content-Type' => 'application/json'}, [{status: 401, error: 'Invalid JSON Web Token'}.to_json]]
        end
      end
    end

    it 'attaches claims to request params if verification passes' do
      JSON::JWT.stub(:decode, claims) do
        prxauth.call(env)['prx.auth'].must_equal claims
      end
    end
  end
end
