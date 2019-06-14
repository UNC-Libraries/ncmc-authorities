module NCMCAuthorities
  module Export
    attr_reader :solr_populated

    def self.export_matches(type)
      type = 'unknown_type' if type == 'unknown'
      names = allnames.send("#{type}_names".to_sym)
      populate_solr unless type == 'personal' || type == 'family'
      write_results(names)
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
  end
end
