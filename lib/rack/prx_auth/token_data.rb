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
        if resource == WILDCARD_RESOURCE_NAME
          globally_authorized?(scope)
        elsif scope.nil?
          authorized_for_resource?(resource, scope)
        else
          authorized_for_resource?(resource, scope) || globally_authorized?(scope)
        end
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
        end
      end
    end
  end
end
