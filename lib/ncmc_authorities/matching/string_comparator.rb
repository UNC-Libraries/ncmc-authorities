module NCMCAuthorities
  module Matching
    module StringComparator
      def compare(name, other_name, **comparison_methods)
        StringComparator.compare(name, other_name, comparison_methods)
      end

      def self.compare(name, other_name, *limited_methods)
        methods =
          if limited_methods.empty?
            %w[sellers levenshtein damerau_levenshtein hamming
               pair_distance longest_subsequence longest_substring
               jaro jaro_winkler trigram].map(&:to_sym)
          else
            limited_methods.uniq
          end

        scores = {}
        methods.each { |mthd| scores[mthd] = send(mthd, name.to_s, other_name.to_s) }
        scores
      end

      def self.sellers(name, other_name)
        Amatch::Sellers.new(name).match(other_name)
      end

      def self.levenshtein(name, other_name)
        name.levenshtein_similar(other_name)
      end

      def self.damerau_levenshtein(name, other_name)
        name.damerau_levenshtein_similar(other_name)
      end

      def self.hamming(name, other_name)
        name.hamming_similar(other_name)
      end

      def self.pair_distance(name, other_name)
        name.pair_distance_similar(other_name)
      end

      def self.longest_subsequence(name, other_name)
        name.longest_subsequence_similar(other_name)
      end

      def self.longest_substring(name, other_name)
        name.longest_substring_similar(other_name)
      end

      def self.jaro(name, other_name)
        name.jaro_similar(other_name)
      end

      def self.jaro_winkler(name, other_name)
        name.jarowinkler_similar(other_name)
      end

      def self.trigram(name, other_name)
        Trigram.compare(name, other_name)
      end

      def self.blah_tokens(name, other_name)
        names = name.split(' ')
        other_names = other_name.split(' ')

        shorter, longer = [names, other_names].sort_by(&:length)
        return 0.9 if shorter.join.empty?
        short_length = shorter.length
        shorter_first = shorter.first
        longer_first = longer.first

        matched = 0
        iter_shorter = shorter.dup
        iter_shorter.each do |token|
          index_in_longer = longer.index(token)
          next unless index_in_longer
          longer.delete_at(index_in_longer)
          shorter.delete_at(shorter.index(token))
          matched += 1
        end

        iter_shorter = shorter.dup
        iter_shorter.each_with_index do |token, idx|
          fuzzy_matched = false
          longer.each do |o|
            lev = levenshtein(token, o)
            next unless lev >= 0.7
            longer.delete_at(longer.index(o))
            shorter.delete_at(shorter.index(token))
            matched += lev
            fuzzy_matched = true
            break
          end
          next if fuzzy_matched
          longer.each do |o|
            next unless token.length == 1 || o.length == 1
            next unless token.chr == o.chr
            longer.delete_at(longer.index(o))
            shorter.delete_at(shorter.index(token))
            matched += 0.8
            break
          end
        end
        penalty_mult = shorter.include?(shorter_first) ? 0.75 : 1
        penalty_mult *= longer.include?(longer_first) ? 0.75 : 1
        if shorter.empty?
          matched / short_length * penalty_mult
        else
          matched * (0.3 ** (shorter.length + shorter.count { |x| x.length > 1 })) * penalty_mult
        end
      end

      def self.blah_initials(name, other_name)
        whatever_value = 0.9
        return whatever_value unless name && other_name
        return whatever_value if name.empty? || other_name.empty?

        names = name.split(' ')
        other_names = other_name.split(' ')
        nscore = names.map do |n|
          [other_names.map { |o| jaro_winkler(n, o)},
          other_names.include?(n.chr) ? 0.9 : 0].flatten.max
        end.reduce(:+) / names.length.to_f
        oscore = other_names.map do |o|
          [names.map { |n| jaro_winkler(o, n)},
          names.include?(o.chr) ? 0.9 : 0].flatten.max
        end.reduce(:+) / other_names.length.to_f
        [nscore, oscore].max
      end
    end
  end
end
