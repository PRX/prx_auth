require 'test_helper'

describe PrxAuth::ResourceMap do
  let(:map) { PrxAuth::ResourceMap.new(input) }
  let(:input) { {'123' => 'admin one two three ns1:namespaced', '456' => 'member four five six' } }

  describe '#authorized?' do
    it 'contains scopes in list' do
      assert map.contains?(123, :admin)
    end

    it 'does not include across aur limits' do
      assert !map.contains?(123, :member)
    end

    it 'does not require a scope' do
      assert map.contains?(123)
    end

    it 'does not match if it hasnt seen the resource' do
      assert !map.contains?(789)
    end

    it 'works with namespaced scopes' do
      assert map.contains?(123, :ns1, :namespaced)
    end

    describe 'with wildcard resource' do
      let(:input) do
        {
          '*' => 'peek',
          '123' => 'admin one two three',
          '456' => 'member four five six'
        }
      end

      it 'applies wildcard lists to queries with no matching value' do
        assert map.contains?(789, :peek)
      end

      it 'does not scan unscoped for wildcard resources' do
        assert !map.contains?(789)
      end

      it 'allows querying by wildcard resource directly' do
        assert map.contains?('*', :peek)
        assert !map.contains?('*', :admin)
      end

      it 'treats wildcard lists as additive to other explicit ones' do
        assert map.contains?(123, :peek)
      end

      it 'refuses to run against wildcard with no scope' do
        assert_raises ArgumentError do
          map.contains?('*')
        end
      end
    end
  end

  describe '#resources' do
    let (:input) do
      {
        '*' => 'read wildcard',
        '123' => 'read write buy',
        '456' => 'read ns1:buy'
      }
    end

    let (:resources) { map.resources }

    it 'returns resource ids' do
      assert resources.include?('123')
      assert resources.include?('456')
    end

    it 'excludes wildcard values' do
      assert !resources.include?('*')
    end

    it 'filters for scope' do
      resources = map.resources(:write)
      assert resources.include?('123')
      assert !resources.include?('456')
      assert !resources.include?('*')
    end

    it 'works with namespaces' do
      resources = map.resources(:ns1, :buy)
      assert resources.include?('123')
      assert resources.include?('456')

      resources = map.resources(:buy)
      assert !resources.include?('456')
    end
  end

  describe '#condense' do
    let (:input) {{ "one" => "one two three ns1:one", "two" => "two three",  "three" => "two", "*" => "two" }}
    let (:json) { map.condense.as_json }

    it "removes redundant values which are in the wildcard" do
      assert !json["one"].include?("two")
    end

    it "keeps resources in the hash even if all scopes are redundant" do
      assert json["three"] == ""
    end
  end
end