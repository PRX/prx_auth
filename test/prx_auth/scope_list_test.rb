require "test_helper"

describe PrxAuth::ScopeList do
  def new_list(val)
    PrxAuth::ScopeList.new(val)
  end

  let(:scopes) { "read write sell  top-up" }
  let(:list) { PrxAuth::ScopeList.new(scopes) }

  it "looks up successfully for a given scope" do
    assert list.contains?("write")
  end

  it "scans for symbols" do
    assert list.contains?(:read)
  end

  it "handles hyphen to underscore conversions" do
    assert list.contains?(:top_up)
  end

  it "fails for contents not in the list" do
    assert !list.contains?(:buy)
  end

  describe "with namespace" do
    let(:scopes) { "ns1:hello ns2:goodbye aloha 1:23" }

    it "works for namespaced lookups" do
      assert list.contains?(:ns1, :hello)
    end

    it "fails when the wrong namespace is passed" do
      assert !list.contains?(:ns1, :goodbye)
    end

    it "looks up global scopes when namespaced fails" do
      assert list.contains?(:ns1, :aloha)
      assert list.contains?(:ns3, :aloha)
    end

    it "works with non-symbol namespaces" do
      assert list.contains?(1, 23)
    end
  end

  describe "#condense" do
    let(:scopes) { "ns1:foo foo ns1:bar" }
    it "removes redundant scopes based on namespace wildcards" do
      assert list.condense.to_s == "foo ns1:bar"
    end
  end

  describe "#-" do
    it "subtracts scopes" do
      sl = new_list("one two") - new_list("two")
      assert sl.is_a? PrxAuth::ScopeList
      assert !sl.contains?(:two)
      assert sl.contains?(:one)
    end

    it "works with scope wildcards" do
      sl = new_list("ns1:one ns2:two") - new_list("one")
      assert !sl.contains?(:ns1, :one)
    end

    it "accepts nil" do
      sl = new_list("one two") - nil
      assert sl.contains?(:one) && sl.contains?(:two)
    end

    it "maintains dashes and capitalization in the result" do
      sl = new_list("The-Beginning the-middle the-end") - new_list("the-Middle")
      assert sl.to_s == "The-Beginning the-end"
    end

    it "dedups and condenses" do
      sl = new_list("one ns1:two ns2:two one three three") - new_list("ns1:two three")
      assert_equal sl.length, 2
      assert_equal sl.to_s, "one ns2:two"
    end
  end

  describe "#+" do
    it "adds scopes" do
      sl = new_list("one") + new_list("two")
      assert sl.is_a? PrxAuth::ScopeList
      assert sl.contains?(:one)
      assert sl.contains?(:two)
    end

    it "dedups and condenses" do
      sl = new_list("one ns1:one two") + new_list("two three") + new_list("two")
      assert_equal sl.length, 3
      assert_equal sl.to_s, "one two three"
    end

    it "accepts nil" do
      sl = new_list("one two") + nil
      assert sl.contains?(:one) && sl.contains?(:two)
    end
  end

  describe "#&" do
    it "gets the intersect of scopes" do
      sl = (new_list("one two three four") & new_list("two four six"))
      assert sl.is_a? PrxAuth::ScopeList
      assert sl.contains?(:two) && sl.contains?(:four)
      assert !sl.contains?(:one) && !sl.contains?(:three) && !sl.contains?(:six)
    end

    it "accepts nil" do
      sl = new_list("one") & nil
      assert !sl.contains?(:one)
    end

    it "works when either side has non-namespaced values correctly" do
      sl = PrxAuth::ScopeList.new("foo:bar") & PrxAuth::ScopeList.new("bar")
      assert sl.contains?(:foo, :bar)
      refute sl.contains?(:bar)

      sl = PrxAuth::ScopeList.new("bar") & PrxAuth::ScopeList.new("foo:bar")
      assert sl.contains?(:foo, :bar)
      refute sl.contains?(:bar)
    end
  end

  describe "==" do
    it "is equal when they are functionally equal" do
      assert_equal PrxAuth::ScopeList.new("foo ns:foo bar ns2:baz"), PrxAuth::ScopeList.new("ns2:baz bar foo")
    end

    it "is not equal when they are not functionally equal" do
      refute_equal PrxAuth::ScopeList.new("foo bar"), PrxAuth::ScopeList.new("foo:bar bar:foo")
    end
  end
end
