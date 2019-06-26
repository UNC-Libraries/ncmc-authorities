module NCMCAuthorities
  module Names
    class Corporate < SubmittedName
      include NCMCAuthorities::NCMCTrigram

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

      def block_keys
        [:all_corporate]
      end

      # add name to a block of similar names
      def self.block(submitted_name)
        submitted_name.block_keys.each do |key|
          block = block_hash[key] || block_hash.add(key)
          block.members << submitted_name unless block.members.include? submitted_name
        end
        nil
      end

      def self.block_hash
        @block_hash ||= BlockHash.new
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
