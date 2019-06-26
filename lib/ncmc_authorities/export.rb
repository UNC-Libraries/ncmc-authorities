require 'set'

module NCMCAuthorities
  module Export
    attr_reader :solr_populated

    def self.export_matches(type, flat: false)
      type = 'unknown_type' if type == 'unknown'
      names = allnames.send("#{type}_names".to_sym)
      populate_solr unless type == 'personal' || type == 'family'
      if flat
        write_flat_results(names)
      else
        write_results(names)
      end
      extra_reporting(type, names)
    end

    def self.export_matches_flat(type)
      type = 'unknown_type' if type == 'unknown'
      names = allnames.send("#{type}_names".to_sym)
      populate_solr unless type == 'personal' || type == 'family'
      write_results(names)
      extra_reporting(type, names)
    end

    def self.extra_reporting(type, names)
      puts "\n----\n"
      puts "type: #{type}"
      puts "submitted names: #{names.length}"
      strong = names.reject { |n| n.strong_matches.empty? }
      not_strong_ct = names.length - strong.length
      puts "submitted names w/unique norm form: #{not_strong_ct}"
      puts "    -- #{not_strong_ct / names.length.to_f}"
      puts "submitted names w/non-unique norm form: #{strong.length}"
      puts "    -- #{strong.length / names.length.to_f}"

      norm_name_forms_that_cluster =
        strong.reduce(0) { |sum, name| sum + name.unique_name_form_percent}
      norm_name_forms = not_strong_ct + norm_name_forms_that_cluster
      puts "norm name forms: #{norm_name_forms}"
      puts "norm name forms w/multiple submitted names: #{norm_name_forms_that_cluster}"
      puts "    -- #{norm_name_forms_that_cluster / (not_strong_ct + norm_name_forms_that_cluster)}"

      instl_overlap =
        strong.select { |n| [n.institution, n.strong_matches.map { |m| m.other_name.institution }].flatten.uniq.length > 1 }
      instl_overlap_ct = instl_overlap.
                          reduce(0) { |sum, name| sum + name.unique_name_form_percent}
      puts "overlap across institutions: #{instl_overlap_ct}"
      puts "    -- #{instl_overlap_ct / norm_name_forms}"

      puts "submitted names in clusters that overlap inst'n: #{instl_overlap.length}"
      puts "    -- #{instl_overlap.length.to_f / names.length}"

      overlap_no_lcnaf_ct =
        instl_overlap.reject { |n| n.lc_reconciled || n.strong_matches.find { |m| m.other_name.lc_reconciled } }.
        reduce(0) { |sum, name| sum + name.unique_name_form_percent}
      puts "overlap across institutions where form not lc reconciled: #{overlap_no_lcnaf_ct}"
      puts "    -- #{overlap_no_lcnaf_ct / instl_overlap_ct}" unless instl_overlap_ct.zero?

      mult_norm_no_lcnaf_ct =
        strong.reject { |n| n.lc_reconciled || n.strong_matches.find { |m| m.other_name.lc_reconciled } }.
        reduce(0) { |sum, name| sum + name.unique_name_form_percent}
      puts "norm w/mult (but regardless of overlap) where not lc reconciled: #{mult_norm_no_lcnaf_ct}"
      puts "    -- #{mult_norm_no_lcnaf_ct / norm_name_forms_that_cluster}"

      any_norm_no_lcnaf_ct =
        names.reject { |n| n.lc_reconciled || n.strong_matches.find { |m| m.other_name.lc_reconciled } }.
          reduce(0) { |sum, name| sum + name.unique_name_form_percent}
      puts "any norm form where not lc reconciled: #{any_norm_no_lcnaf_ct}"
      puts "    -- #{any_norm_no_lcnaf_ct / norm_name_forms}"


    end

    def self.allnames
      @allnames ||= NCMCAuthorities::Import::SubmittedNameGetter.new
    end

    def self.populate_solr
      return if @solr_populated

      unknown = allnames.unknown_type_names

      corporate = allnames.corporate_names
      NCMCAuthorities::Names::Corporate.solr.add_docs(
        corporate, unknown.map(&:corporate)
      )

      meeting = allnames.meeting_names
      NCMCAuthorities::Names::Meeting.solr.add_docs(
        meeting, unknown.map(&:meeting)
      )

      @solr_populated = true
    end

    def self.write_results(names)
      type = names.first.type
      File.open("test_results_#{type}.txt", 'w') do |ofile|
        names.each do |pname|
          strong = pname.strong_matches
          moderate = pname.moderate_matches
          weak = pname.weak_matches
          if (strong + moderate + weak).empty?
            pname.clear_ranking
            next
          end

          ofile << "#{pname.name}\n"
          ofile << "Strong:\n" if strong
          strong.each do |match|
            ofile << "\t#{match.other_name}\t#{match.score}\n"
          end
          ofile << "Moderate:\n" if moderate
          moderate.each do |match|
            ofile << "\t#{match.other_name}\t#{match.score}\n"
          end
          ofile << "Weak:\n" if weak
          weak.each do |match|
            ofile << "\t#{match.other_name}\t#{match.score}\n"
          end
          ofile << "\n\n"

          pname.clear_ranking
        end
      end
    end

    def self.write_flat_results(names)
      type = names.first.type
      File.open("test_results_#{type}_flat.txt", 'w') do |ofile|
        seen = Set.new
        res = []
        names.each do |pname|
          seen << pname

          matches = pname.strong_matches + pname.moderate_matches

          if matches.empty?
            pname.clear_ranking
            next
          end

          matches.each do |match|
            next if seen.include? match.other_name
            res << [pname.name, match.other_name, match.score]
          end
          pname.clear_ranking
        end

        res.sort_by { |name, other, score| [-score, name, other] }.uniq.each do |r|
          ofile << "#{r.join("\t")}\n"
        end
      end
    end
  end
end
