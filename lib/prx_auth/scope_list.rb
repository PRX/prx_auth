module PrxAuth
  class ScopeList
    SCOPE_SEPARATOR = ' '
    NAMESPACE_SEPARATOR = ':'
    NO_NAMESPACE = :_

    def self.new(list)
      case list
      when PrxAuth::ScopeList then list
      else super(list)
      end
    end

    def initialize(list)
      @string = list
    end

    def contains?(namespace, scope=nil)
      scope, namespace = namespace, NO_NAMESPACE if scope.nil?

      if namespace == NO_NAMESPACE
        map[namespace].include?(symbolize(scope))
      else
        symbolized_scope = symbolize(scope)
        map[symbolize(namespace)].include?(symbolized_scope) || map[NO_NAMESPACE].include?(symbolized_scope)
      end
    end

    def freeze
      @string.freeze
      self
    end

    def to_s
      @string
    end

    def condense
      tripped = false
      result = map[NO_NAMESPACE].clone
      namespaces = map.keys - [NO_NAMESPACE]

      namespaces.each do |ns|
        map[ns].each do |scope|
          if !contains?(NO_NAMESPACE, scope)
            result << scope_string(ns, scope)
          else
            tripped = true
          end
        end
      end

      if tripped
        ScopeList.new(result.join(SCOPE_SEPARATOR))
      else
        self
      end
    end

    def as_json(opts=())
      to_s.as_json(opts)
    end

    def -(other_scope_list)
      return self if other_scope_list.nil?

      tripped = false
      result = []

      map.each do |namespace, scopes|
        scopes.each do |scope|
          if other_scope_list.contains?(namespace, scope)
            tripped = true
          else
            result << scope_string(namespace, scope)
          end
        end
      end

      if tripped
        ScopeList.new(result.join(SCOPE_SEPARATOR))
      else
        self
      end
    end

    def +(other_list)
      return self if other_list.nil?

      ScopeList.new([to_s, other_list.to_s].join(SCOPE_SEPARATOR)).condense
    end

    def &(other_list)
      return ScopeList.new('') if other_list.nil?
      
      self - (self - other_list)
    end

    private

    def map
      @parsed_map ||= empty_map.tap do |map|
        @string.split(SCOPE_SEPARATOR).each do |value|
          next if value.length < 1

          parts = value.split(NAMESPACE_SEPARATOR, 2)
          if parts.length == 2
            map[symbolize(parts[0])] << symbolize(parts[1])
          else
            map[NO_NAMESPACE] << symbolize(parts[0])
          end
        end
      end
    end

    def scope_string(ns, scope)
      if ns == NO_NAMESPACE
        scope.to_s
      else
        [ns, scope].join(NAMESPACE_SEPARATOR)
      end
    end

    def empty_map
      @empty_map ||= Hash.new do |hash, key|
        hash[key] = []
      end
    end

    def symbolize(value)
      case value
      when Symbol then value
      when String then value.downcase.gsub('-', '_').intern
      else symbolize value.to_s
      end
    end
  end
end
