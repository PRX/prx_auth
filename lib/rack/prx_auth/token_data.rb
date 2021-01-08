require 'prx_auth/resource_map'

module Rack
  class PrxAuth
    class TokenData
      attr_reader :scopes

      def initialize(attrs = {})
        @attributes = attrs

        @authorized_resources = ::PrxAuth::ResourceMap.new(unpack_aur(attrs['aur'])).freeze
        
        if attrs['scope']
          @scopes = attrs['scope'].split(' ').freeze
        else
          @scopes = [].freeze
        end
      end

      def resources(namespace=nil, scope=nil)
        @authorized_resources.resources(namespace, scope)
      end

      def user_id
        @attributes['sub']
      end

      def authorized?(resource, namespace=nil, scope=nil)
        @authorized_resources.contains?(resource, namespace, scope)
      end

      def globally_authorized?(namespace, scope=nil)
        authorized?(::PrxAuth::ResourceMap::WILDCARD_KEY, namespace, scope)
      end

      def authorized_account_ids(scope)
        resources(::PrxAuth::Rails.configuration.namespace, scope).map(&:to_i)
      end

      private

      def unpack_aur(aur)
        return {} if aur.nil?

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
