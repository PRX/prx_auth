module PrxAuth
  class ScopeList < Array
    SCOPE_SEPARATOR = ' '
    NAMESPACE_SEPARATOR = ':'
    NO_NAMESPACE = :_

    Entry = Struct.new(:namespace, :scope)

    class Entry
      def equal?(other_entry)
        namespace == other_entry.namespace && scope == other_entry.scope
      end

      def to_s
        if namespaced?
          "#{namespace}:#{scope}"
        else
          scope.to_s
        end
      end

      def namespaced?
        !(namespace.nil? || namespace == NO_NAMESPACE)
      end

      def unnamespaced
        if namespaced?
          Entry.new(NO_NAMESPACE, scope)
        else
          self
        end
      end
    end

    def self.new(list)
      case list
      when PrxAuth::ScopeList then list
      when Array then super(list.join(' '))
      else super(list)
      end
    end

    def initialize(list)
      @string = list
      @string.split(SCOPE_SEPARATOR).each do |value|
        next if value.length < 1

        parts = value.split(NAMESPACE_SEPARATOR, 2)
        if parts.length == 2
          push Entry.new(symbolize(parts[0]), symbolize(parts[1]))
        else
          push Entry.new(NO_NAMESPACE, symbolize(parts[0]))
        end
      end
    end

    def contains?(namespace, scope=nil)
      entries = if scope.nil?
                  scope, namespace = namespace, NO_NAMESPACE 
                  [Entry.new(namespace, symbolize(scope))]
                else
                  scope = symbolize(scope)
                  namespace = symbolize(namespace)
                  [Entry.new(namespace, scope), Entry.new(NO_NAMESPACE, scope)]
                end
      
      entries.any? do |possible_match|
        include?(possible_match)
      end
    end

    def to_s
      @string
    end

    def condense
      tripped = false
      result = []

      each do |entry|
        if entry.namespaced? && include?(entry.unnamespaced)
          tripped = true
        else
          result << entry
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

      each do |entry|
        if other_scope_list.include?(entry) || other_scope_list.include?(entry.unnamespaced)
          tripped = true
        else
          result << entry
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

    def symbolize(value)
      case value
      when Symbol then value
      when String then value.downcase.gsub('-', '_').intern
      else symbolize value.to_s
      end
    end
  end
end
