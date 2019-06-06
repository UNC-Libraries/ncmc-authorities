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

      def similarity(name, other_name)
        @matrix[@model.document_index(name), @model.document_index(other_name)]
      end

      def self.trigrams(norm_name)
        attributes = []
        terms = norm_name.split(' ')
        terms.each do |t|
          attributes << t.chars.each_cons(3).map(&:join)
          attributes << ["#{t[0..2]}!", "#{t[0..2]}!"]
          attributes << "#{t.chr}#"
        end
        terms.each_cons(2).map { |a, b| "#{a.chr} #{b.chr}" }
        attributes.flatten!
      end

      def self.tfidf_doc(norm_name, trigrams)
        TfIdfSimilarity::Document.new(
          norm_name,
          term_counts: trigrams.group_by { |x| x }.map { |k,v| [k, v.length] }.to_h,
          size: trigrams.length
        )
      end
    end
  end
end
