require 'test_helper'

describe PrxAuth::ScopeList do
  let (:scopes) { 'read write sell  top-up' }
  let (:list) { PrxAuth::ScopeList.new(scopes) }

  it 'looks up successfully for a given scope' do
    assert list.contains?('write')
  end
  
  it 'scans for symbols' do
    assert list.contains?(:read)
  end

  it 'handles hyphen to underscore conversions' do
    assert list.contains?(:top_up)
  end

  it 'fails for contents not in the list' do
    assert !list.contains?(:buy)
  end

  describe 'with namespace' do
    let (:scopes) { 'ns1:hello ns2:goodbye aloha 1:23' }
    
    it 'works for namespaced lookups' do
      assert list.contains?(:ns1, :hello)
    end

    it 'fails when the wrong namespace is passed' do
      assert !list.contains?(:ns1, :goodbye)
    end

    it 'looks up global scopes when namespaced fails' do
      assert list.contains?(:ns1, :aloha)
      assert list.contains?(:ns3, :aloha)
    end

    it 'works with non-symbol namespaces' do
      assert list.contains?(1, 23)
    end
  end

end