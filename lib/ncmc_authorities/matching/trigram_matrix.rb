require 'tf-idf-similarity'
require 'narray'

module NCMCAuthorities
  module Matching
    class TrigramMatrix
      attr_reader :matrix, :model

      def initialize(corpus)
        @corpus = corpus
        @model = TfIdfSimilarity::TfIdfModel.new(corpus, :library => :narray)
        @matrix = @model.similarity_matrix
      end

      def similarity(doc_index, other_doc_index)
        @matrix[doc_index, other_doc_index]
        #@matrix[@model.document_index(tfidf_doc),
        #        @model.document_index(other_tfidf_doc)]
      end

      # Returns an array of trigrams from given string.
      #
      #  The trigrams are:
      #   - each 3-letter char sequence within each word
      #   - two occurences of the first 3-letter sequence of each word
      #     followed by "!"
      #   - the first character of each word followed by "#"
      #   - the first characters of each two word sequence in the name,
      #     separated by a space
      #  (per: https://ii.nlm.nih.gov/MTI/Details/trigram.shtml)
      #
      # example:
      # 	name: American Home Foods
      #   trigrams: ["ame", "mer", "eri", "ric", "ica", "can",
      #              "ame!", "ame!", "a#",
      #              "hom", "ome",
      #              "hom!", "hom!", "h#",
      #              "foo", "ood", "ods",
      #              "foo!", "foo!", "f#"
      #              "a h", "h f"]
      def self.trigrams(norm_name)
        attributes = []
        terms = norm_name.split(' ')
        terms.each do |t|
          attributes << t.chars.each_cons(3).map(&:join)
          attributes << ["#{t[0..2]}!", "#{t[0..2]}!"]
          attributes << "#{t.chr}#"
        end
        attributes << terms.each_cons(2).map { |a, b| "#{a.chr} #{b.chr}" }
        attributes.flatten!
      end

      # Returns a TfIdfSimilarity::Document for a given string and trigram-array
      def self.tfidf_doc(norm_name, trigrams)
        TfIdfSimilarity::Document.new(
          norm_name,
          term_counts: trigrams.group_by { |x| x }.map { |k,v| [k, v.length] }.to_h,
          size: trigrams.length
        )
      end

      # Create a corpus from array(s) of objects that respond to :tfidf_doc
      def self.corpus_from_array(*arry)
        i = 0
        arry.flatten.map do |name|
          name.model_index = i
          i += 1
          name.tfidf_doc
        end
      end
    end
  end
end
