module Rack
  class PrxAuth
    class TokenData
      def initialize(attrs = {})
        @attributes = attrs
        @user_id = attrs['sub']
      end

      attr_reader :attributes, :user_id
    end
  end
end
