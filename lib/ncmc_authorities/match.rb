module NCMCAuthorities
  class Match
    attr_reader :name, :other_name, :solr_score, :explanation

    def initialize(name1, name2, solr_score = nil, explanation = nil)
      @name = name1
      @other_name = name2
      @solr_score = solr_score
      @explanation = explanation
    end

    def names
      [@name, @other_name]
    end

    def score
      return @score if @score

      @score, @explanation = self.class.score(name, other_name, name.type, self)
      @score
    end

    def explanation
      return @explanation if @explanation

      @score, @explanation = self.class.score(name, other_name, name.type, self)
      @explanation
    end

    def category
      @category = self.class.categorize(score, name.type)
    end

    def self.rank(name, other_names)
      other_names.
        uniq.
        reject { |m| m.equal? name }.
        map { |other| Match.new(name, other) }.
        sort_by { |match| [-match.score, match.other_name ] }
    end

    def self.categorize(score, type)
      case type
      when 'personal', 'family'
        case score
        when 0.9..100.0
          :strong
        when 0.8..0.9
          :moderate
        when 0.7..0.8
          :weak
        else
          :bad
        end
      when 'corporate', 'meeting'
        case score
        when 0.85..100.0
          :strong
        when 0.60..0.85
          :moderate
        when 0.55..0.60
          :weak
        else
          :bad
        end
      end
    end

    def self.score(name, other_name, name_type, match)
      send(:"#{name_type}_score", name, other_name, match)
    end

    # Corporate names have a score from solr assigned to the match
    def self.corporate_score(name, other_name, match)
      check_lcnaf(name, other_name, match.solr_score, match.explanation)
    end

    # Meeting names have a score from solr assigned to the match
    def self.meeting_score(name, other_name, match)
      corporate_score(name, other_name, match)
    end


    def self.family_score(name, other_name, _)
      score = StringComparator.compare(name.basename, other_name.basename, :levenshtein)[:levenshtein]
      explanation = {base_score: score, severity: 1,
                      weight: 1, score: score}
      check_lcnaf(name, other_name, score, explanation)
    end

    def self.variant_switcher(name, other_name)
      unless name.variant_forename || other_name.variant_forename
        return [name.forename, other_name.forename, false]
      end

      if name.variant_forename && other_name.variant_forename
        return [name.variant_forename, other_name.variant_forename, true]
      end

      lacks_var, has_var =
        [name, other_name].sort_by{ |n| n.variant_forename.to_s.length }

      orig_and_var = [has_var.forename, has_var.variant_forename].
                      sort_by(&:length)

      selected_name =
        if lacks_var.forename.to_s.split(' ').find { |x| x.length > 1 }
          orig_and_var.last
        else
          orig_and_var.first
        end
      uses_variants = selected_name != has_var.forename

      if lacks_var == name
        [name.forename, selected_name, uses_variants]
      else
        [selected_name, other_name.forename, uses_variants]
      end
    end

    def self.personal_score(name, other_name, _)
      surname = StringComparator.compare(name.surname, other_name.surname, :levenshtein)

      name_fore, other_fore, use_variants = variant_switcher(name, other_name)
      forename = StringComparator.compare(name_fore, other_fore, :levenshtein, :forename_tokens)
      supplemental = StringComparator.compare(name.supplemental, other_name.supplemental, :trigram)

      factors = [
        ['surname levenshtein', surname[:levenshtein], 1.5, 5],
        ['forename levenshtein', forename[:levenshtein], 1, 1],
        ['forename tokens', forename[:forename_tokens], 1, 4],
        ['supplemental',
          supplemental[:trigram].nan? ? 1.0 : supplemental[:trigram], 1, 1]
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

      explanation[:variant_forename_used] = true if use_variants
      score, explanation = cap_partial_names(name, other_name, score, explanation)
      score, explanation = check_dates(name, other_name, score, explanation)
      check_lcnaf(name, other_name, score, explanation)
    end

    # cap the base scores when names are very incomplete (e.g. "Smith" or
    # "Smith, P"
    # dates/lcnaf matching can still rase these base scores
    def self.cap_partial_names(name, other_name, score, explanation)
      return [score, explanation] if score >= 1.0

      names = [name, other_name]
      # one name is only a surname
      if names.find { |n| n.forename.nil? && n.supplemental.nil? }
        adjusted_score = [score, 0.8].min
        explanation[:surname_only_cap] = true
      elsif names.find { |n| n.forename.length == 1 && n.supplemental.nil? }
        adjusted_score = [score, 0.9].min
        explanation[:surname_and_initial_cap] = true
      else
        return [score, explanation]
      end

      return [adjusted_score, explanation]

    end

    # Reward scores for matching dates, penalize scores for non-matching dates
    def self.check_dates(name, other_name, score, explanation)
      return [score, explanation] if name.dates.empty? || other_name.dates.empty?
      return [score, explanation] if name.dates.length > 2 || other_name.dates.length > 2

      shorter, longer = [name.dates.map(&:to_i), other_name.dates.map(&:to_i)].sort_by(&:length)

      m = 0
      nm = 0
      # Expect that when two dates are present they are in order (e.g, a
      # lifespan or active period range).
      # When one date is present, it could be the start or end of the range,
      # so we wouldn't want to compare it only to the first of two dates on
      # another name
      if shorter.length == 2
        shorter.each_with_index do |date, i|
          if (longer[i] - date).abs.between?(-1, 1)
            m += 1
          else
            nm += 1
          end
        end
      else
        date = shorter.first
        if longer.include?(date) || !longer.select { |d| (d - date).abs == 1 }.empty?
          m += 1
        else
          nm += 1
        end
      end

      # Targetted so that for perfectly matching names, one net date mismatch
      # ends up being the high end of moderate and two net date mismatches
      # ends up being the low end of moderate (but still above the .8
      # cap_partial_names score).
      mod =
        case m - nm
        when 2
          2
        when 1
          1.5
        when 0
          1.0
        when -1
          0.89
        when -2
          0.801
        end

      adjusted_score =
        if mod >= 1.0
          score ** (1.0/mod)
        else
          score * mod
        end
      explanation[:dates] = {base_score: score, score: adjusted_score}

      [adjusted_score, explanation]
    end

    # on lcnaf id/string match, bump scores to largest of sixth root or the
    # low end of :weak category for name type
    def self.check_lcnaf(name, other_name, score, explanation)
      lcnaf_match =
        if name.lcnaf_id && name.lcnaf_id == other_name.lcnaf_id
          [:lcnaf_id, name.lcnaf_id]
        elsif name.lcnaf_string && Names::SubmittedName.normalize_name(name.lcnaf_string) == Names::SubmittedName.normalize_name(other_name.lcnaf_string)
          [:lcnaf_string, name.lcnaf_string]
        end
      return [score, explanation] unless lcnaf_match

      matchpoint, matchvalue = lcnaf_match

      min_weak =
        case name.type
        when 'personal', 'family'
          0.7
        when 'corporate', 'meeting'
          0.55
        end
      adjusted_score = [score ** (1.0/6.0), min_weak].max
      explanation[matchpoint] = {match_value: matchvalue, base_score: score, score: adjusted_score}
      [adjusted_score, explanation]
    end
  end
end
