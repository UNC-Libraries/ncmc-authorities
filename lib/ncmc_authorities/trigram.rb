module NCMCAuthorities
  module NCMCTrigram
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
    #   name: American Home Foods
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

    # used with solr tokenizer that splits on whitespace but does not remove
    # punctuation.
    def self.solr_trigram_string(norm_name)
      trigrams(norm_name).map { |t| t.tr(' ', '_') }.join(' ')
    end

    def trigrams
      NCMCTrigram.trigrams(norm_name)
    end

    def solr_trigram_string
      NCMCTrigram.solr_trigram_string(norm_name)
    end
  end
end
