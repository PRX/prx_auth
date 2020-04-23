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

      if @wildcard
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

      if @wildcard
        result[WILDCARD_KEY] = @wildcard - (@wildcard - other_wildcard)
      end

      ResourceMap.new(result).condense
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

    protected

    def list_for_resource(resource)
      return @wildcard if resource.to_s == WILDCARD_KEY
      @map[resource.to_s]
    end
  end
end
