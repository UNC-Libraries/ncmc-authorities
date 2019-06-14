require 'rsolr'



=begin
solr start -e cloud
solr create_collection -c corporate
solr delete -c corporate
=end


module NCMCAuthorities
  module NCMCSolr
    BASEURL = 'http://127.0.0.1:9983/solr/'

    class Collection
      attr_reader :corpus

      def initialize(collection_name)
        @collection_name = collection_name
      end

      def solr
        @solr ||= RSolr.connect :url => "#{BASEURL}#{@collection_name}"
      end

      def purge
        solr.delete_by_query 'id:*'
      end

      def add_docs(*doc_arry)
        doc_arry.flatten!
        purge
        @corpus = doc_arry
        docs = doc_arry.each_with_index.map do |obj, idx|
          {id: idx,
          name: obj.name,
          trigrams_ws: obj.solr_trigram_string}
        end
        solr.add docs
        solr.commit
      end

      def find_matches(doc)
        r = @solr.get 'select', :params => {
          df: 'trigrams_ws',
          fl: 'id,name,score',
          q: doc.solr_trigram_string,
          :rows=>100
        }
        SolrMatchResponse.new(r, @corpus.find_index(doc))
      end

      def ranking(doc)
        find_matches(doc).normalized_scores.map do |x|
          NCMCAuthorities::Matching::Match.new(
            doc, @corpus[x.last.to_i], x.first
          )
        end
      end
    end

    class SolrMatchResponse
      attr_reader :response

      def initialize(response, doc_id)
        @response = response
        @doc_id = doc_id
      end

      def docs
        @response["response"]["docs"].reject { |x| x["id"] == @doc_id.to_s }
      end

      def normalized_scores
        docs.map { |x| [x["score"]/self_score, x["name"].first, x["id"]] }
      end

      def self_score
        @response["response"]["docs"].find { |x| x["id"] == @doc_id.to_s }["score"]
      end

    end
  end
end
