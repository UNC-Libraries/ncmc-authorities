# encoding: utf-8

require 'active_support/inflector'
require 'pp'

module NCMCAuthorities
  module Names
    class SubmittedName
      include Comparable

      attr_reader :hsh
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
        #@hsh = nh
        @name = nh[:name]
        @norm_name = normalized_name
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
        cluster
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

      def normalized_name
        self.class.normalize_name(@name)
      end

      def clusters_keys; end

      def clusters
        return unless @clustered
        cluster_keys.map { |k| self.class.cluster_hash[k] }
      end

      def ranking
        @ranking ||= Matching::Match.rank(self, clusters.map { |x| x.members.to_a }.flatten)
      end

      def clear_ranking
        @ranking = nil
      end

      def matches(category)
        ranking.select { |m| m.category == category }
      end

      # These examples below aren't canon. Some might be right, some are
      # probably not.

      # Names that match very well and sufficient info exists that
      # Along the lines of:
      #   e.g. Smith, Pat Cornsbury, 1912-1950 => Smith, Pat Cornsbury, 1912
      #   e.g. Smith, Pat A => Smith, Pat Alex
      #   e.g. Smith, Pat => Smith, Pat
      def strong_matches
        matches(:strong)
      end

      # names that match moderately well with sufficient info to support it, and
      # names that match well but a low amount of information/specificity
      # make the match uncertain
      # Along the lines of:
      #   e.g. Smith, P Ann => Smith, P Anne
      def moderate_matches
        matches(:moderate)
      end

      # worse than moderate and better than bad?
      #   e.g. Smith, P => Smith, Pat
      #   e.g. Smith, P => Smith, P F
      def weak_matches
        matches(:weak)
      end

      # matches that probably users aren't interested in and should not
      # see; however, they are not so terrible that they should be entirely
      # discarded. Potentially useful for testing and making sure we're
      # not effectively discarding things that should rank better
      def bad_matches
        matches(:bad)
      end

      # This can be summed to find the count of "Normalized name forms that
      # cluster multiple submitted names"
      #
      # Our fuzzy matching is not transitive (if A matches B and C, B and C
      # will both match A, but B and C do not need to match), so we're not
      # able to simply count A (or B or C) as 1 normalized name form
      # and discard the rest. Instead, each name counts 1/(n+1) where
      # n is the number of [strong] matches.
      def unique_name_form_percent
        1.0 / (strong_matches.length + 1)
      end

      private
      def self.normalize_name(name)
        return unless name

        name = name.downcase
        name = name.unicode_normalize(:nfkd).gsub(/\p{Mn}/, '')
        name.delete!("'")
        name =  name.
                gsub(/&/, ' and ').
                gsub(/\s+/, ' ').
                strip
        name = name.parameterize.gsub('-', ' ')
      end

      def self.clean_name_type(value)
        case value.downcase
        when 'agent_family'
          'family'
        when 'conference'
          'meeting'
        when 'person'
          'personal'
        when ''
          'unknown'
        else
          value.downcase
        end
      end

      def self.factory(nh, file = nil, ct = nil, type_limit: nil)
        type = clean_name_type(nh[:name_type].to_s)
        return unless type_limit.nil? || type == type_limit

        case type
        when 'personal'
          Names::Personal.new(nh, file, ct)
        when 'corporate'
          Names::Corporate.new(nh, file, ct)
        when 'family'
          Names::Family.new(nh, file, ct)
        when 'meeting'
          Names::Meeting.new(nh, file, ct)
        when 'unknown'
          Names::Unknown.new(nh, file, ct)
        else
          SubmittedName.new(nh, file, ct)
        end
      end

      def cluster
        self.class.cluster(self)
        @clustered = true
      end
    end
  end
end
