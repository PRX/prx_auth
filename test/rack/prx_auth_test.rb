require "test_helper"

describe Rack::PrxAuth do
  let(:app) { proc { |env| env } }
  let(:prxauth) { Rack::PrxAuth.new(app) }
  let(:fake_token) { "afawefawefawefawegstgnsrtiohnlijblublwjnvrtoign" }
  let(:env) { {"HTTP_AUTHORIZATION" => "Bearer " + fake_token} }
  let(:iat) { Time.now.to_i }
  let(:exp) { 3600 }
  let(:claims) { {"sub" => 3, "exp" => exp, "iat" => iat, "token_type" => "bearer", "scope" => nil, "iss" => "id.prx.org"} }

  describe "#call" do
    it "does nothing if there is no authorization header" do
      env = {}

      assert prxauth.call(env.clone) == env
    end

    it "does nothing if the token is from another issuer" do
      claims["iss"] = "auth.elsewhere.org"

      JSON::JWT.stub(:decode, claims) do
        assert prxauth.call(env.clone) == env
      end
    end

    it "does nothing if token is invalid" do
      assert prxauth.call(env.clone) == env
    end

    it "does nothing if the token is nil" do
      env = {"HTTP_AUTHORIZATION" => "Bearer "}
      assert prxauth.call(env) == env
    end

    it "returns 401 if verification fails" do
      auth_validator = prxauth.build_auth_validator("sometoken")

      JSON::JWT.stub(:decode, claims) do
        prxauth.stub(:build_auth_validator, auth_validator) do
          auth_validator.stub(:valid?, false) do
            assert prxauth.call(env) == Rack::PrxAuth::INVALID_TOKEN
          end
        end
      end
    end

    it "returns 401 if access token has expired" do
      auth_validator = prxauth.build_auth_validator("sometoken")

      JSON::JWT.stub(:decode, claims) do
        prxauth.stub(:build_auth_validator, auth_validator) do
          auth_validator.stub(:expired?, true) do
            assert prxauth.call(env) == Rack::PrxAuth::INVALID_TOKEN
          end
        end
      end
    end

    it "attaches claims to request params if verification passes" do
      auth_validator = prxauth.build_auth_validator("sometoken")

      JSON::JWT.stub(:decode, claims) do
        prxauth.stub(:build_auth_validator, auth_validator) do
          prxauth.call(env)["prx.auth"].tap do |token|
            assert token.instance_of? Rack::PrxAuth::TokenData
            assert token.user_id == claims["sub"]
          end
        end
      end
    end
  end

  describe "initialize" do
    it "takes a certificate location as an option" do
      loc = nil
      Rack::PrxAuth::Certificate.stub(:new, proc { |l| loc = l }) do
        Rack::PrxAuth.new(app, cert_location: :location)
        assert loc == :location
      end
    end
  end
end
