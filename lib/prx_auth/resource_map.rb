module PrxAuth
  class ResourceMap
    WILDCARD_KEY = '*'

    def initialize(mapped_values)
      input = mapped_values.clone
      @wildcard = ScopeList.new(input.delete(WILDCARD_KEY)||'')
      @map = Hash[input.map do |(key, values)|
        [key, ScopeList.new(values)]
      end]
    end

    def contains?(resource, namespace=nil, scope=nil)
      resource = resource.to_s

      if resource == WILDCARD_KEY
        raise ArgumentError if namespace.nil?
      
        @wildcard.contains?(namespace, scope)
      else
        mapped_resource = @map[resource]
        
        if mapped_resource && !namespace.nil?
          mapped_resource.contains?(namespace, scope) || @wildcard.contains?(namespace, scope)
        elsif !namespace.nil?
          @wildcard.contains?(namespace, scope)
        else
          !!mapped_resource
        end
      end
    end

    def condense
      condensed_wildcard = @wildcard.condense
      condensed_map = Hash[@map.map do |resource, list|
        [resource, (list - condensed_wildcard).condense]
      end]
      ResourceMap.new(condensed_map.merge(WILDCARD_KEY => condensed_wildcard))
    end

    def as_json(opts={})
      @map.merge(WILDCARD_KEY => @wildcard).as_json(opts)
    end

    def freeze
      @map.freeze
      @wildcard.freeze
      self
    end

    def resources(namespace=nil, scope=nil)
      if namespace.nil?
        @map.keys
      else
        @map.select do |name, list|
          list.contains?(namespace, scope) || @wildcard.contains?(namespace, scope)
        end.map(&:first)
      end
    end
  end
end
