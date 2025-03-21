require "test_helper"

describe PrxAuth::ResourceMap do
  def new_map(val)
    PrxAuth::ResourceMap.new(val)
  end

  let(:map) { PrxAuth::ResourceMap.new(input) }
  let(:input) { {"123" => "admin one two three ns1:namespaced", "456" => "member four five six"} }

  describe "#authorized?" do
    it "contains scopes in list" do
      assert map.contains?(123, :admin)
    end

    it "does not include across aur limits" do
      assert !map.contains?(123, :member)
    end

    it "does not require a scope" do
      assert map.contains?(123)
    end

    it "does not match if it hasnt seen the resource" do
      assert !map.contains?(789)
    end

    it "works with namespaced scopes" do
      assert map.contains?(123, :ns1, :namespaced)
    end

    describe "with wildcard resource" do
      let(:input) do
        {
          "*" => "peek",
          "123" => "admin one two three",
          "456" => "member four five six"
        }
      end

      it "applies wildcard lists to queries with no matching value" do
        assert map.contains?(789, :peek)
      end

      it "does not scan unscoped for wildcard resources" do
        assert !map.contains?(789)
      end

      it "allows querying by wildcard resource directly" do
        assert map.contains?("*", :peek)
        assert !map.contains?("*", :admin)
      end

      it "treats wildcard lists as additive to other explicit ones" do
        assert map.contains?(123, :peek)
      end

      it "refuses to run against wildcard with no scope" do
        assert_raises ArgumentError do
          map.contains?("*")
        end
      end
    end
  end

  describe "#resources" do
    let(:input) do
      {
        "*" => "read wildcard",
        "123" => "read write buy",
        "456" => "read ns1:buy"
      }
    end

    let(:resources) { map.resources }

    it "returns resource ids" do
      assert resources.include?("123")
      assert resources.include?("456")
    end

    it "excludes wildcard values" do
      assert !resources.include?("*")
    end

    it "filters for scope" do
      resources = map.resources(:write)
      assert resources.include?("123")
      assert !resources.include?("456")
      assert !resources.include?("*")
    end

    it "works with namespaces" do
      resources = map.resources(:ns1, :buy)
      assert resources.include?("123")
      assert resources.include?("456")

      resources = map.resources(:buy)
      assert !resources.include?("456")
    end
  end

  describe "#condense" do
    let(:input) { {"one" => "one two three ns1:one", "two" => "two three", "three" => "two", "*" => "two"} }
    let(:json) { map.condense.as_json }

    it "removes redundant values which are in the wildcard" do
      assert !json["one"].include?("two")
    end

    it "keeps resources in the hash even if all scopes are redundant" do
      assert json["three"] == ""
    end
  end

  describe "#+" do
    it "adds values" do
      map = new_map("one" => "two", "two" => "four") + new_map("one" => "three", "three" => "six")
      assert map.contains?("one", :two) && map.contains?("one", :three)
      assert map.contains?("two", :four) && map.contains?("three", :six)
    end
  end

  describe "#-" do
    it "subtracts values" do
      map = new_map("one" => "two three", "two" => "four") - new_map("one" => "three four")
      assert map.contains?("one", :two)
      assert map.contains?("two", :four)
      assert !map.contains?("one", :three) && !map.contains?("one", :four)
    end

    it "works on wildcards on right side of operator" do
      map = new_map("one" => "two three") - new_map("*" => "two")
      assert !map.contains?("one", :two)
    end
  end

  describe "#&" do
    it "computes the intersection" do
      map = (
        new_map("one" => "two three", "four" => "five six", "five" => "five") &
        new_map("one" => "three four", "four" => "six seven", "six" => "six")
      )
      assert map.contains?("one", :three) && map.contains?("four", :six)
      assert !map.contains?("one", :two) && !map.contains?("four", :five)
      assert !map.contains?("one", :four) && !map.contains?("four", :seven)
      assert !map.contains?("five", :five) && !map.contains?("six", :six)
    end

    it "works with wildcards" do
      map = new_map("*" => "three wild", "one" => "four two") & new_map("*" => "two wild", "two" => "three four")
      assert map.contains?("two", :three) && map.contains?("one", :two)
      assert !map.contains?("one", :four) && !map.contains?("two", :four)
      assert map.contains?("*", :wild)
    end

    it "works with global scoped wildcards" do
      map = new_map("*" => "something") & new_map("*" => "ns1:something")
      assert map.contains?("*", "ns1", :something)
    end
  end

  describe "#as_json" do
    it "does not include wildcard key if list is empty" do
      map = new_map("foo" => "asdf")
      refute map.as_json.has_key?("*")
      map2 = new_map("foo" => "asdf", "*" => "")
      refute map2.as_json.has_key?("*")
    end

    it "includes the wildcard key if the list is not empty" do
      map = new_map("*" => "asdf")
      assert map.as_json.has_key?("*")
    end
  end

  describe "#[]" do
    it "automatically stringifies" do
      refute_nil map[123]
    end
  end

  describe "#[]=" do
    it "automatically stringifies" do
      map[789] = PrxAuth::ScopeList.new("")
      refute_nil map["789"]
    end
  end

  describe "#except" do
    it "removes keys" do
      map2 = map.except(123)

      assert_equal ["123", "456"], map.keys
      assert_equal ["456"], map2.keys

      # the ! version modifies the map
      map2.except!("456")
      assert_equal [], map2.keys
    end
  end
end
