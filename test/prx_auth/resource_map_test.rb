require 'test_helper'

describe PrxAuth::ResourceMap do
  let(:map) { PrxAuth::ResourceMap.new(resources) }
  let(:resources) { {'123' => 'admin one two three ns1:namespaced', '456' => 'member four five six' } }

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
      let(:resources) do
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
end