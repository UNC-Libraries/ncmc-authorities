module NCMCAuthorities
  module Names
    class Corporate < SubmittedName
      include NCMCAuthorities::Trigram

      attr_accessor :model_index

      def initialize(*args)
        super
        @type = self.class.type
      end

      def basename
        norm_name
      end

      def self.normalize_name(name)
        return unless name

        name = name.downcase
        name = name.unicode_normalize(:nfkd).gsub(/\p{Mn}/, '')
        name.delete!("'")
        name.parameterize.
          tr('-', ' ').
          gsub(/\b(of|the|and)\b/, '').
          gsub(/\s+/, ' ').
          strip
      end

      def trigrams
        Matching::TrigramMatrix.trigrams(norm_name)
      end

      def cluster_keys
        [:all_corporate]
      end

      def self.cluster(submitted_name)
        submitted_name.cluster_keys.each do |key|
          cluster = cluster_hash[key] || cluster_hash.add(key)
          cluster.members << submitted_name unless cluster.members.include? submitted_name
        end
        nil
      end

      def self.cluster_hash
        @cluster_hash ||= ClusterHash.new
      end

      def self.type
        'corporate'
      end

      def self.solr
        @solr ||= NCMCAuthorities::NCMCSolr::Collection.new(type)
      end

      def ranking
        @ranking ||= self.class.solr.ranking(self)
      end
    end
  end
end
