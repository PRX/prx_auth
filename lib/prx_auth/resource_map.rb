module PrxAuth
  class ResourceMap < Hash
    WILDCARD_KEY = '*'

    def initialize(mapped_values)
      super() do |hash, key|
        if key == WILDCARD_KEY
          @wildcard
        else
          nil
        end
      end
      input = mapped_values.clone
      @wildcard = ScopeList.new(input.delete(WILDCARD_KEY)||'')
      input.each do |(key, values)|
        self[key.to_s] = ScopeList.new(values)
      end
    end

    def contains?(resource, namespace=nil, scope=nil)
      resource = resource.to_s

      if resource == WILDCARD_KEY
        raise ArgumentError if namespace.nil?
      
        @wildcard.contains?(namespace, scope)
      else
        mapped_resource = self[resource]
        
        if mapped_resource && !namespace.nil?
          mapped_resource.contains?(namespace, scope) || @wildcard.contains?(namespace, scope)
        elsif !namespace.nil?
          @wildcard.contains?(namespace, scope)
        else
          !!mapped_resource
        end
      end
    end

    def [](key)
      super(key.to_s)
    end

    def []=(key, value)
      super(key.to_s, value)
    end

    def condense
      condensed_wildcard = @wildcard.condense
      condensed_map = Hash[map do |resource, list|
        [resource, (list - condensed_wildcard).condense]
      end]
      ResourceMap.new(condensed_map.merge(WILDCARD_KEY => condensed_wildcard))
    end

    def +(other_map)
      result = {}
      (resources + other_map.resources + [WILDCARD_KEY]).uniq.each do |resource|
        list_a = list_for_resource(resource)
        list_b = other_map.list_for_resource(resource)
        result[resource] = if list_a.nil?
                             list_b
                           elsif list_b.nil?
                             list_a
                           else
                             list_a + list_b
                           end
      end

      ResourceMap.new(result).condense
    end

    def -(other_map)
      result = {}
      other_wildcard = other_map.list_for_resource(WILDCARD_KEY) || PrxAuth::ScopeList.new('')

      resources.each do |resource|
        result[resource] = list_for_resource(resource) - (other_wildcard + other_map.list_for_resource(resource))
      end

      if @wildcard.length
        result[WILDCARD_KEY] = @wildcard - other_wildcard
      end

      ResourceMap.new(result)
    end

    def &(other_map)
      result = {}
      other_wildcard = other_map.list_for_resource(WILDCARD_KEY)
      
      (resources + other_map.resources).uniq.each do |res|
        left = list_for_resource(res)
        right = other_map.list_for_resource(res)

        result[res] = if left.nil?
                        right & @wildcard
                      elsif right.nil?
                        left & other_wildcard
                      else
                        (left + @wildcard) & (right + other_wildcard)
                      end
      end

      if @wildcard.length > 0
        result[WILDCARD_KEY] = @wildcard - (@wildcard - other_wildcard)
      end

      ResourceMap.new(result).condense
    end

    def as_json(opts={})
      super(opts).merge(@wildcard.length > 0 ? {WILDCARD_KEY => @wildcard}.as_json(opts) : {})
    end

    def resources(namespace=nil, scope=nil)
      if namespace.nil?
        keys
      else
        select do |name, list|
          list.contains?(namespace, scope) || @wildcard.contains?(namespace, scope)
        end.map(&:first)
      end
    end

    protected

    def list_for_resource(resource)
      self[resource.to_s]
    end
  end
end
