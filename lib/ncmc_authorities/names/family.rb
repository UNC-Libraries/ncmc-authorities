module NCMCAuthorities
  module Names
    class Family < SubmittedName

      def initialize(*args)
        super
        @type = 'family'
      end

      def basename
        @basename ||= self.class.normalize_name(name)
      end

      def word_tokens
        basename.split(' ')
      end

      def cluster_keys
        self.class.cluster_keys(word_tokens)
      end

      def self.cluster_keys(word_tokens)
        word_tokens.map { |n| Text::Soundex.soundex(n) }
      end

      def self.cluster(submitted_name)
        clusts = cluster_keys(submitted_name.word_tokens).
                 map { |sdx| cluster_hash[sdx] || cluster_hash.add(sdx) }
        clusts.each { |c| c.members << submitted_name unless c.members.include? submitted_name }
        nil
      end

      def self.cluster_hash
        @cluster_hash ||= ClusterHash.new
      end

      def self.normalize_name(name)
        return unless name

        name = name.downcase
        name = name.unicode_normalize(:nfkd).gsub(/\p{Mn}/, '')
        name.gsub!(/\b(family|the|and)\b/, '')
        name.delete("'")
        name.parameterize.tr('-', ' ')
      end
    end
  end
end

