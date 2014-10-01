module Rack
  class PrxAuth
    class TokenData
      def initialize(attrs = {})
        @attributes = attrs
      end

      attr_reader :attributes
    end
  end
end
