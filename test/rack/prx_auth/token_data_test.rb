require "test_helper"

describe Rack::PrxAuth::TokenData do
  it "pulls user_id from sub" do
    token = Rack::PrxAuth::TokenData.new("sub" => 123)
    token.user_id.must_equal 123
  end

  it "pulls authorized_resources from aur" do
    token = Rack::PrxAuth::TokenData.new("aur" => { "123" => "admin" })
    token.authorized_resources["123"].must_equal "admin"
  end

  it "unpacks compressed aur into authorized_resources" do
    token = Rack::PrxAuth::TokenData.new(
      "aur" => {
        "123" => "member",
        "$" => {
          "admin" => [456, 789, 1011]
        }
      }
    )
    token.authorized_resources["$"].must_be_nil
    token.authorized_resources["789"].must_equal "admin"
    token.authorized_resources["123"].must_equal "member"
  end

  describe "#authorized?" do
    let(:token) { Rack::PrxAuth::TokenData.new("aur" => aur, "scope" => scope) }
    let(:scope) { "read write purchase sell delete" }
    let(:aur) { { "123" => "admin", "456" => "member" } }

    it "is authorized for scope in aur" do
      assert token.authorized?(123, "admin")
    end

    it "is authorized for scope in scopes" do
      assert token.authorized?(456, :delete)
    end

    it "is not authorized across aur limits" do
      assert !token.authorized?(123, :member)
    end

    it "does not require a scope" do
      assert token.authorized?(123)
    end

    it "is unauthorized if it hasnt seen the resource" do
      assert !token.authorized?(789)
    end
  end
end
