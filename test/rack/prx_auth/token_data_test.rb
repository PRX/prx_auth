require "test_helper"

describe Rack::PrxAuth::TokenData do
  it "pulls user_id from sub" do
    token = Rack::PrxAuth::TokenData.new("sub" => 123)
    assert token.user_id == 123
  end

  it "pulls resources from aur" do
    token = Rack::PrxAuth::TokenData.new("aur" => {"123" => "admin"})
    assert token.resources.include?("123")
  end

  it "unpacks compressed aur" do
    token = Rack::PrxAuth::TokenData.new("aur" => {
      "123" => "member",
      "$" => {
        "admin" => [456, 789, 1011]
      }
    })
    assert !token.resources.include?("$")
    assert token.resources.include?("789")
    assert token.resources.include?("123")
  end

  describe "#resources" do
    let(:token) { Rack::PrxAuth::TokenData.new("aur" => aur) }
    let(:aur) { {"123" => "admin ns1:namespaced", "456" => "member"} }

    it "scans for resources by namespace and scope" do
      assert token.resources(:admin) == ["123"]
      assert token.resources(:namespaced) == []
      assert token.resources(:member) == ["456"]
      assert token.resources(:ns1, :namespaced) == ["123"]
      assert token.resources(:ns1, :member) == ["456"]
    end
  end

  describe "#authorized?" do
    let(:token) { Rack::PrxAuth::TokenData.new("aur" => aur, "scope" => scope) }
    let(:scope) { "read write purchase sell delete" }
    let(:aur) { {"123" => "admin ns1:namespaced", "456" => "member"} }

    it "is authorized for scope in aur" do
      assert token.authorized?(123, "admin")
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

    it "works for namespaced scopes" do
      assert token.authorized?(123, :ns1, :namespaced)
      assert !token.authorized?(123, :namespaced)
      assert token.authorized?(123, :ns1, :admin)
    end

    describe "with wildcard role" do
      let(:aur) { {"*" => "peek", "123" => "admin", "456" => "member"} }

      it "applies wildcard tokens to queries with no matching aur" do
        assert token.authorized?(789, :peek)
      end

      it "does not authorize unscoped for wildcard resources" do
        assert !token.authorized?(789)
      end

      it "allows querying by wildcard resource directly" do
        assert token.authorized?("*", :peek)
        assert !token.authorized?("*", :admin)
      end

      it "has a shorthand `gobally_authorized?` to query wildcard" do
        assert token.globally_authorized?(:peek)
        assert !token.globally_authorized?(:admin)
      end

      it "treats global authorizations as additive to other explicit ones" do
        assert token.authorized?(123, :peek)
      end

      it "refuses to run `globally_authorized?` with no scope" do
        assert_raises ArgumentError do
          token.globally_authorized?
        end
        assert_raises ArgumentError do
          token.authorized?("*")
        end
      end
    end

    describe "#except" do
      let(:token) { Rack::PrxAuth::TokenData.new("aur" => aur) }
      let(:aur) { {"123" => "admin ns1:namespaced", "456" => "member"} }

      it "removes resources from the aur" do
        token2 = token.except(123)

        assert token.authorized?(123, "admin")
        assert token.authorized?(456, "member")

        refute token2.authorized?(123, "admin")
        assert token2.authorized?(456, "member")

        # the ! version modifies the token
        token2.except!(456)
        refute token2.authorized?(456, "member")
      end
    end

    describe "#empty_resources?" do
      it "checks if the user has access to any resources" do
        token = Rack::PrxAuth::TokenData.new("aur" => {"123" => "anything"})
        refute token.empty_resources?
        assert token.except("123").empty_resources?
      end

      it "checks for empty scopes" do
        token = Rack::PrxAuth::TokenData.new("aur" => {"123" => ""})
        assert token.empty_resources?
      end

      it "is not empty with wildcard auth" do
        token = Rack::PrxAuth::TokenData.new("aur" => {"*" => "anything"})
        refute token.empty_resources?
      end
    end
  end
end
