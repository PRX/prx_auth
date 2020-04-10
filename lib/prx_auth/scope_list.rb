module PrxAuth
  class ScopeList
    SCOPE_SEPARATOR = ' '
    NAMESPACE_SEPARATOR = ':'
    NO_NAMESPACE = :_

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
