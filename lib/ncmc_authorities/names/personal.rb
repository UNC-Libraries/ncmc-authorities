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
        normalize_name(variant).
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

      def cluster_keys
        self.class.cluster_keys(surnames)
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
        supplemental = normalize_name(supplemental.join(','))
        surname = normalize_name(surname)

        forename_variant = normalize_name(forename_variant(forename))
        forename = remove_variants(forename)
        forename = normalize_name(forename)

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

      def self.normalize_name(name)
        return unless name

        name = name.downcase
        name = name.unicode_normalize(:nfkd).gsub(/\p{Mn}/, '')
        name.delete!("'")
        name.parameterize.
          tr('-', ' ').
          gsub(/[0-9]{3,}/, '').
          gsub(/\s+/, ' ').
          strip
      end
    end
  end
end
