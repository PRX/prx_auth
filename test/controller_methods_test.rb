require 'minitest/autorun'
require 'minitest/spec'
require 'minitest/pride'
require 'rack/prx_auth'
require 'rack/prx_auth/controller_methods'
require 'rack/prx_auth/token_data'

class FakeController
  include Rack::PrxAuth::ControllerMethods
  attr_accessor :request

  Request = Struct.new('Request', :env)

  def initialize(env)
    self.request = Request.new(env)
  end
end

describe Rack::PrxAuth::ControllerMethods do
  let(:claims) { {'sub'=>nil, 'exp'=>3600, 'iat'=>Time.now.to_i, 'token_type'=>'bearer', 'scope'=>nil, 'iss'=>'id.prx.org'} }
  let(:token_data) { Rack::PrxAuth::TokenData.new(claims) }
  let(:env) { {'prx.auth' => token_data } }
  let(:empty_env) { Hash.new }

  describe '#prx_auth_token' do
    it 'returns the token data object' do
      FakeController.new(env).prx_auth_token.must_equal token_data
    end

    it 'returns nil if there is no prx.auth field' do
      FakeController.new(empty_env).prx_auth_token.must_be_nil
    end
  end

  describe '#prx_authenticated?' do
    it 'returns false if there is no token data' do
      FakeController.new(empty_env).prx_authenticated?.must_equal false
    end

    it 'must be true if there is token data' do
      FakeController.new(env).prx_authenticated?.must_equal true
    end
  end
end
