module NCMCAuthorities
  module Names
    class Meeting < Corporate

      def initialize(*args)
        super
      end

      def self.type
        'meeting'
      end

      def block_keys
        [:all_meeting]
      end
    end
  end
end
