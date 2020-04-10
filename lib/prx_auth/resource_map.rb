module PrxAuth
  class ResourceMap
    WILDCARD_KEY = '*'

    def initialize(mapped_values)
      @map = Hash[mapped_values.map do |(key, values)|
        [key, ScopeList.new(values)]
      end]
    end

    def contains?(resource, namespace=nil, scope=nil)
      mapped_resource = @map[resource.to_s]

      if mapped_resource == wildcard_resource
        raise ArgumentError if namespace.nil?
      
        mapped_resource.contains?(namespace, scope)
      elsif mapped_resource && !namespace.nil?
        mapped_resource.contains?(namespace, scope) || wildcard_resource.contains?(namespace, scope)
      elsif !namespace.nil?
        wildcard_resource.contains?(namespace, scope)
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
