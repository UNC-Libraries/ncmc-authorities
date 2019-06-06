module NCMCAuthorities
  module Names
    class Corporate < SubmittedName
      def basename
        norm_name
      end

      def trigrams
        @trigrams ||= Matching::TrigramMatrix.trigrams(norm_name)
      end

      def tfidf_doc
        @tfidf_doc ||= Matching::TrigramMatrix.tfidf_doc(norm_name, trigrams)
      end

      def trigram_matrix
        Corporate.trigram_matrix
      end

      def trigram_similarity(other_name)
        trigram_matrix.similarity(tfidf_doc, other_name.tfidf_doc)
      end

      def cluster_keys
        @cluster_keys ||= trigrams.select{ |str| str[-1] == '!' }.uniq
      end

      def clusters
        self.class.cluster(self) unless @clustered
        @clustered = true
        cluster_keys.map { |k| self.class.cluster_hash[k] }
      end

      def self.trigram_matrix(corpus = nil)
        return @trigram_matrix if @trigram_matrix
        return unless corpus

        @trigram_matrix = Matching::TrigramMatrix.new(corpus)
      end

      def self.cluster(submitted_name)
        submitted_name.cluster_keys.each do |trigram|
          cluster = cluster_hash[trigram] || cluster_hash.add(trigram)
          cluster.members << submitted_name unless cluster.members.include? submitted_name
        end
        nil
      end

      def self.cluster_hash
        @cluster_hash ||= ClusterHash.new
      end

      # These examples below aren't canon. Some might be right, some are
      # probably not. In any case, classification will vary by name_type.

      # Names that match very well and sufficient info exists that
      # Along the lines of:

      def strong_matches
        ranking.select { |m| m.score >= 0.75 }
      end

      # names that match moderately well with sufficient info to support it
      # names that match well but a low amount of information/specificity
      # make the match uncertain


      def moderate_matches
        ranking.select { |m| m.score >= 0.5 && m.score < 0.75}
      end

      # worse than moderate and better than bad?

      def weak_matches
        ranking.select { |m| m.score >= 0.4 && m.score < 0.5}
      end

      # matches that probably users aren't interested in and should not
      # see; however, they are not so terrible that they should be entirely
      # discarded. Potentially useful for testing and making sure we're
      # not effectively discarding things that should rank better
      def bad_matches
        ranking.select { |m| m.score < 0.4 }
      end
    end
  end
end
