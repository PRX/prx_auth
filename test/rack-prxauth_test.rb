require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'
require_relative '../lib/rack/prxauth'

describe Rack::PrxAuth do
  let(:app) { Proc.new {|env| env } }
  let(:reader) { Rack::PrxAuth.new(app) }
  let(:env) { {'HTTP_AUTHORIZATION' => 'Bearer zdawefawefawefw' } }
  let(:claims) { claims = {'sub'=>nil, 'exp'=>3600, 'iat'=>1411668422, 'token_type'=>'bearer', 'scope'=>nil} }

  describe '#call' do
    it 'does nothing if there is no authorization header' do
      env = {}

      reader.call(env).must_equal env
    end

    it 'returns 401 if verification fails' do
      raise_error = Proc.new { raise JSON::JWT::VerificationFailed }

      JSON::JWT.stub(:decode, raise_error) do
        reader.call(env).must_equal [401, {'Content-Type' => 'application/json'}, [{status: 401, error: 'Invalid JSON Web Token'}.to_json]]
      end
    end

    it 'attaches claims to request params if verification passes' do
      JSON::JWT.stub(:decode, claims) do
        reader.call(env)['prx.auth'].must_equal claims
      end
    end
  end
end
