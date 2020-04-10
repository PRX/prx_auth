module PrxAuth
  class ResourceMap
    WILDCARD_KEY = '*'

    def initialize(mapped_values)
      @map = Hash[mapped_values.map do |(key, values)|
        [key, ScopeList.new(values)]
      end]
    end

    def contains?(resource, scope=nil)
      mapped_resource = @map[resource.to_s]
      if mapped_resource == wildcard_resource
        raise ArgumentError if scope.nil?
      
        mapped_resource.contains?(scope)
      elsif mapped_resource && !scope.nil?
        mapped_resource.contains?(scope) || wildcard_resource.contains?(scope)
      elsif !scope.nil?
        wildcard_resource.contains?(scope)
      else
        !!mapped_resource
      end
    end

    private

    def wildcard_resource
      @wildcard_resource ||= @map[WILDCARD_KEY] || ScopeList.new('')
    end
  end
end
