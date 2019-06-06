module NCMCAuthorities
  module Names
    class Personal < SubmittedName

      def initialize(*args)
        super
        @type = 'personal'
      end

      def parsed_name
        @parsed_name ||= Personal.parse(name)
      end

      def self.dates(name)
        normalize_name(name).scan(/[0-9]{3,}/)
      end

      def self.initials(name)
        return unless name

        name.split(' ').map(&:chr).join
      end

      def self.forename_variant(name)
        return unless name

        variant = name.
                  scan(/\(([^)]*)\)/).
                  join(' ')
        normalize(variant).
          gsub(/\s+/, ' ').
          strip
      end

      def self.remove_variants(name)
        return unless name

        name = name.gsub(/\([^)]*\)/, '')
        name.
          gsub(/\s+/, ' ').
          strip
      end

      def surnames
        surname.split(' ')
      end

      def forenames
        forename.split(' ')
      end

      def surname
        parsed_name[:surname]
      end

      def forename
        parsed_name[:forename]
      end

      def basename
        "#{surname} #{forename}"
      end

      def supplemental
        parsed_name[:supplemental]
      end

      def dates
        parsed_name[:dates]
      end

      def initials
        parsed_name[:initials]
      end

      def forename_initials
        parsed_name[:forename_initials]
      end

      def variant_initials
        parsed_name[:variant_initials]
      end


      # These examples below aren't canon. Some might be right, some are
      # probably not.

      # Names that match very well and sufficient info exists that
      # Along the lines of:
      #   e.g. Smith, Pat Cornsbury, 1912-1950 => Smith, Pat Cornsbury, 1912
      #   e.g. Smith, Pat A => Smith, Pat Alex
      #   e.g. Smith, Pat => Smith, Pat
      def strong_matches
        ranking.select { |m| m.score >= 0.9 }
      end

      # names that match moderately well with sufficient info to support it, and
      # names that match well but a low amount of information/specificity
      # make the match uncertain
      # Along the lines of:
      #   e.g. Smith, P Ann => Smith, P Anne

      def moderate_matches
        ranking.select { |m| m.score >= 0.8 && m.score < 0.9}
      end

      # worse than moderate and better than bad?
      #   e.g. Smith, P => Smith, Pat
      #   e.g. Smith, P => Smith, P F
      def weak_matches
        ranking.select { |m| m.score >= 0.7 && m.score < 0.8}
      end

      # matches that probably users aren't interested in and should not
      # see; however, they are not so terrible that they should be entirely
      # discarded. Potentially useful for testing and making sure we're
      # not effectively discarding things that should rank better
      def bad_matches
        ranking.select { |m| m.score < 0.7 }
      end

      def cluster_keys
        Personal.cluster_keys(surnames)
      end

      def clusters
        self.class.cluster(self) unless @clustered
        @clustered = true
        cluster_keys.map { |k| self.class.cluster_hash[k] }
      end

      def self.cluster_keys(surnames)
        surnames.map { |n| Text::Soundex.soundex(n) }
      end

      def self.cluster(submitted_name)
        clusts = cluster_keys(submitted_name.surnames).
                 map { |sdx| cluster_hash[sdx] || cluster_hash.add(sdx) }
        clusts.each { |c| c.members << submitted_name unless c.members.include? submitted_name }
        nil
      end

      def self.cluster_hash
        @cluster_hash ||= ClusterHash.new
      end

      def self.parse(name)
        surname, forename, *supplemental = name.split(',')
        supplemental = normalize(supplemental.join(','))
        surname = normalize(surname)

        forename_variant = normalize(forename_variant(forename))
        forename = remove_variants(forename)
        forename = normalize(forename)

        dates = dates(name)

        forename_initials = initials(forename)
        variant_initials = initials(forename_variant)
        initials = initials("#{surname} #{forename}")

        {
          surname: surname,
          forename: forename,
          supplemental: supplemental,
          dates: dates,
          forename_variant: forename_variant,
          initials: initials,
          forename_initials: forename_initials,
          variant_initials: variant_initials
        }
      end

      def self.normalize(name)
        return unless name

        normalize_name(name).
          gsub(/[0-9]{3,}/, '').
          gsub(/\s+/, ' ').
          strip
      end

      def self.normalize_name(name)
        return unless name

        name = name.downcase
        name = name.unicode_normalize(:nfkd).gsub(/\p{Mn}/, '')
        name.delete("'")
        name.parameterize.tr('-', ' ')
      end
    end
  end
end
