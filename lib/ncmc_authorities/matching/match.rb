module NCMCAuthorities
  module Matching
    class Match
      attr_reader :name, :other_name, :score, :explanation
      def initialize(name1, name2)
        @name = name1
        @other_name = name2
      end

      def names
        [@name, @other_name]
      end

      def score
        @score, @explanation = self.class.score(name, other_name, name.type)
        @score
      end

      def self.rank(name, other_names)
        other_names = other_names.
                      uniq.
                      reject { |m| m.equal? name}

        # Eliminate names with pretty terrible surname/forename match scores
        if name.type == 'personal'
          other_names.reject! do |other|
            res = Matching::StringComparator.compare(name.basename, other.basename, :levenshtein)
            res[:levenshtein] <= 0.5
          end
        end

        other_names.map! do |other|
          Match.new(name, other)
        end

        other_names.sort_by { |match| [-match.score, match.other_name ] }
      end

      def self.score(name, other_name, name_type)
        send(:"#{name_type}_score", name, other_name)
      end

      def self.corporate_score(name, other_name)
        [
          Matching::StringComparator.compare(name.norm_name, other_name.norm_name, :trigram)[:trigram],
          nil
        ]
      end

      def self.personal_score(name, other_name)
        surname = Matching::StringComparator.compare(name.surname, other_name.surname, :levenshtein)
        forename = Matching::StringComparator.compare(name.forename, other_name.forename, :levenshtein, :blah_tokens)
        #initials = Matching::StringComparator.compare(name.initials, other_name.initials, :jaro_winkler)
        supplemental = Matching::StringComparator.compare(name.supplemental, other_name.supplemental, :trigram, :levenshtein)
        #dates = 0

        factors = [
          ['surname levenshtein', surname[:levenshtein], 1.5, 5],
          ['forename levenshtein', forename[:levenshtein], 1, 1],
          ['forename whatever', forename[:blah_tokens], 1, 4],
          ['supplemental',
          supplemental[:trigram].nan? ? supplemental[:levenshtein] : supplemental[:trigram],
          1, 1]
        ]

        explanation = {}
        factors.each do |row|
          fname, base_score, severity, weight = row
          score = base_score ** severity * weight
          explanation[fname] = {base_score: base_score, severity: severity,
                              weight: weight, score: score}
        end

        score = (explanation.values.map { |v| v[:score] }.reduce(:+)) / \
          (explanation.values.map { |v| v[:weight] }.reduce(:+))

        [score, explanation]
      end
    end
  end
end
