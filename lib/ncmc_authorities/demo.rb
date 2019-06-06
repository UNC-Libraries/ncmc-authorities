# load files
load 'lib/ncmc_authorities.rb'

# get all names with little/no deduping
allnames = NCMCAuthorities::Import::SubmittedNameGetter.new

# limit to personal names
personal = allnames.personal_names
personal.count

pname = personal.first
c = pname.clusters.first

# see matches that qualify as "strong" according to the criteria
#   in SubmittedName.strong_matches
pname.strong_matches

def test_results(names)
  File.open('test_results.txt', 'w') do |ofile|
    names.each do |pname|
      strong = pname.strong_matches
      moderate = pname.moderate_matches
      weak = pname.weak_matches
      # bad = pname.bad_matches
      next if (strong + moderate + weak).empty?

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
      # ofile << "Bad:\n" if bad
      # bad.each do |match|
      #   ofile << "\t#{match.other_name.inspect}\t#{match.score}\n"
      # end
      ofile << "\n\n"
    end
  end
end

# write test results for personal names with matches
test_results(personal)
exit

# personal names with strong matches
strong = personal.reject { |p| p.strong_matches.empty? }
strong.count
personal.count

# get only corporate names
corporate = NCMCAuthorities::Import::SubmittedNameGetter.new(type_limit: 'corporate').names

# generate a corpus of corporate name trigrams
corpus = corporate.map(&:tfidf_doc)
m = NCMCAuthorities::Names::Corporate.trigram_matrix(corpus)

# write test results for corporate names
test_results(corporate)
