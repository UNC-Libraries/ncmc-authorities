# encoding: utf-8

require 'active_support/inflector'
require 'pp'

module NCMCAuthorities
  module Names
    class SubmittedName
      include Comparable

      attr_reader :name
      attr_reader :norm_name
      attr_reader :type
      attr_reader :variants
      attr_reader :relator
      attr_reader :lcnaf_string
      attr_reader :lcnaf_uri
      attr_reader :institution
      attr_reader :source_system
      attr_reader :collection
      attr_reader :source_system_full
      attr_reader :coll_full
      attr_reader :source_file
      attr_reader :name_id
      attr_reader :lc_reconciled

      # initialized with:
      #  - hash of name data from tsv row
      #  - name of source file
      #  - count of source file row
      def initialize(nh, file = nil, ct = nil)
        @name = nh[:name]
        @norm_name = normalize_name(@name)
        @type = SubmittedName.clean_name_type(nh[:name_type].to_s)
        @variants = nh[:variants].split(';;;').map { |v| v.strip } if nh[:variants]
        @relator = nh[:role_or_relator]
        @lcnaf_string = nh[:lcnaf_string]
        @lcnaf_uri = nh[:lcnaf_uri]
        @institution = nh[:institution]&.upcase
        @source_system = nh[:source_system]&.downcase
        @source_system_full = "#{@institution}-#{@source_system}"
        if (nh[:collection].nil? || nh[:collection].empty?)
          @collection = 'none'
        else
          @collection = nh[:collection]
        end
        @coll_full = "#{@source_system_full}-#{@collection}"
        @source_file = file
        @name_id = "#{file}#{ct}"
        @lc_reconciled = false
        @lc_reconciled = true unless (@lcnaf_uri.nil? || @lcnaf_uri.empty?)
        @lc_reconciled = true unless (@lcnaf_string.nil? || @lcnaf_string.empty?)
        @clustered = false

        clusters
      end

      def inspect
        name
      end

      def to_s
        name
      end

      def <=>(other)
        self.name <=> other.name
      end

      def personal?
        true if type == 'personal'
      end

      def family?
        true if type == 'family'
      end

      def corporate?
        true if type == 'corporate'
      end

      def meeting?
        true if type == 'meeting'
      end

      def unknown_type?
        true if type == 'unknown'
      end

      def clusters; end

      def ranking
        @ranking ||= Matching::Match.rank(self, clusters.map(&:members).flatten)
      end

      private
      def normalize_name(name)
        return unless name

        name = name.downcase
        name = name.unicode_normalize(:nfkd).gsub(/\p{Mn}/, '')
        name.delete("'")
        name =  name.
                gsub(/&/, ' and ').
                gsub(/\s+/, ' ').
                strip
        name = name.parameterize.gsub('-', ' ')
      end

      def self.clean_name_type(value)
        case value
        when 'agent_family'
          type = 'family'
        when 'conference'
          type = 'meeting'
        when 'person'
          type = 'personal'
        when ''
          type = 'unknown'
        else
          type = value
        end
        type.downcase
      end

      def self.factory(nh, file = nil, ct = nil, type_limit: nil)
        type = clean_name_type(nh[:name_type].to_s)
        return unless type_limit.nil? || type == type_limit

        case type
        when 'personal'
          Names::Personal.new(nh, file, ct)
        when 'corporate'
          Names::Corporate.new(nh, file, ct)
        else
          SubmittedName.new(nh, file, ct)
        end
      end
    end
  end
end
