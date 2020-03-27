module Rack
  class PrxAuth
    class TokenData
      WILDCARD_RESOURCE_NAME = '*'

      attr_reader :attributes, :authorized_resources, :scopes

      def initialize(attrs = {})
        @attributes = attrs
        if attrs['aur']
          @authorized_resources = unpack_aur(attrs['aur']).freeze
        else
          @authorized_resources = {}.freeze
        end
        if attrs['scope']
          @scopes = attrs['scope'].split(' ').freeze
        else
          @scopes = [].freeze
        end
      end

      def user_id
        @attributes['sub']
      end

      def authorized?(resource, scope=nil)
        return globally_authorized?(scope) if resource == WILDCARD_RESOURCE_NAME

        authorized_for_resource?(resource, scope) || (scope.nil? ? false : globally_authorized?(scope))
      end

      def globally_authorized?(scope)
        raise ArgumentError if scope.nil?

        authorized_for_resource?(WILDCARD_RESOURCE_NAME, scope)
      end
      private

      def authorized_for_resource?(resource, scope=nil)
        if auth = authorized_resources[resource.to_s]
          scope.nil? || (scopes + auth.split(' ')).include?(scope.to_s)
        end
      end

      def unpack_aur(aur)
        aur.clone.tap do |result|
          unless result['$'].nil?
            result.delete('$').each do |role, resources|
              resources.each do |res|
                result[res.to_s] = role
              end
            end
          end
          if result[WILDCARD_RESOURCE_NAME].nil? && result['0']
            result[WILDCARD_RESOURCE_NAME] = result.delete('0')
          end
        end
      end
    end
  end
end
