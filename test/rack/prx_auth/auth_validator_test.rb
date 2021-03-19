require 'test_helper'

describe Rack::PrxAuth::AuthValidator do
  let(:app) { Proc.new {|env| env } }
  let(:auth_validator) { Rack::PrxAuth::AuthValidator.new(token, certificate, 'id.local.test') }

  let(:token) { 'some.token.foo' }

  let(:iat) { Time.now.to_i }
  let(:exp) { 3600 }
  let(:claims) { {'sub'=>3, 'exp'=>exp, 'iat'=>iat, 'token_type'=>'bearer', 'scope'=>nil, 'iss'=>'id.prx.org'} }
  let(:certificate) { Rack::PrxAuth::Certificate.new }

  describe '#token_issuer_matches' do
    it 'false if the token is from another issuer' do
      auth_validator.stub(:claims, claims) do
        refute auth_validator.token_issuer_matches?
      end
    end

    it 'is false if the issuer in the validator does not match' do
      auth_validator.stub(:issuer, 'id.foo.com') do
        refute auth_validator.token_issuer_matches?
      end
    end
  end

  describe '#valid?' do
    it 'is false if token is invalid' do
      auth_validator.stub(:claims, claims) do
        refute auth_validator.valid?
      end
    end

    it 'is false if the token is nil' do
      certificate.stub(:valid?, true) do
        auth_validator.stub(:token, nil) do
          refute auth_validator.valid?
        end
      end
    end
  end

  describe '#expired?' do

    def expired?(claims)
      auth_validator.stub(:claims, claims) do
        auth_validator.expired?
      end
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

  describe '#time_to_live' do
    def time_to_live(claims)
      auth_validator.stub(:claims, claims) do
        auth_validator.time_to_live
      end
    end

    it 'returns the ttl without any clock jitter correction' do
      claims['exp'] = Time.now.to_i + 999
      assert_equal time_to_live(claims), 999
    end

    it 'handles missing exp' do
      claims['exp'] = nil
      assert_equal time_to_live(claims), 0
    end

    it 'handles missing iat' do
      claims['iat'] = nil
      claims['exp'] = Time.now.to_i + 999
      assert_equal time_to_live(claims), 999
    end

    it 'handles malformed exp' do
      claims['iat'] = Time.now.to_i
      claims['exp'] = 999
      assert_equal time_to_live(claims), 999
    end
  end

  describe '#decode_token' do
    it 'should return an empty result for a nil token' do
        auth_validator.stub(:token, nil) do
          assert auth_validator.decode_token == {}
        end
    end

    it 'should return an empty result for an empty token' do
        auth_validator.stub(:token, '') do
          assert auth_validator.decode_token == {}
        end
    end

    it 'should return an empty result for a malformed token' do
        auth_validator.stub(:token, token) do
          assert auth_validator.decode_token == {}
        end
    end
  end
end
