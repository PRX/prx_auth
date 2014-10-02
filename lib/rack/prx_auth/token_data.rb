module Rack
  class PrxAuth
    class TokenData
      def initialize(attrs = {})
        @attributes = attrs
      end

      attr_reader :attributes

      def user_id
        @attributes['sub']
      end
    end
  end
end
