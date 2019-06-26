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
        name.scan(/[0-9]{3,}/)
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
        variant = normalize_name(variant).
                  gsub(/\s+/, ' ').
                  strip
        return if variant == ''

        variant
      end

      def self.remove_variants(name)
        return unless name

        name = name.gsub(/\([^)]*\)/, '')
        name.
          gsub(/\s+/, ' ').
          strip
      end

      def surnames
        return [] unless surname

        surname.split(' ')
      end

      def forenames
        return [] unless forename

        forename.split(' ')
      end

      def surname
        parsed_name[:surname]
      end

      def forename
        parsed_name[:forename]
      end

      # content extracted from parenthetical "fuller form of name added as a
      # qualifier"
      def variant_forename
        parsed_name[:forename_variant]
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

      def block_keys
        self.class.block_keys(surnames)
      end

      def self.block_keys(surnames)
        surnames.map { |n| Text::Soundex.soundex(n) }
      end

      # add name to a block of similar names
      def self.block(submitted_name)
        clusts = block_keys(submitted_name.surnames).
                 map { |sdx| block_hash[sdx] || block_hash.add(sdx) }
        clusts.each { |c| c.members << submitted_name unless c.members.include? submitted_name }
        nil
      end

      def self.block_hash
        @block_hash ||= BlockHash.new
      end

      def self.parse(name)
        surname, forename, *supplemental = name.split(',')

        supplemental = normalize_name(supplemental.join(','))
        supplemental = nil if supplemental == ''

        surname = normalize_name(surname)

        forename_variant = normalize_name(forename_variant(forename))
        forename = normalize_name(remove_variants(forename))

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
