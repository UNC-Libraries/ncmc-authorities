# load files
load 'lib/ncmc_authorities.rb'

# get all names with little/no deduping
allnames = NCMCAuthorities::Import::SubmittedNameGetter.new

# count of names by type
allnames.names.group_by { |n| n.type }.map { |k, v| [k, v.length]}.to_h

# limit to personal names
personal = allnames.personal_names
personal.count

pname = personal.first
c = pname.clusters.first

# see matches that qualify as "strong" according to the criteria
#   in SubmittedName.strong_matches
pname.strong_matches

def test_results(names)
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

# write test results for personal names with matches
test_results(personal)

exit

# you can also import only personal names by
personal = NCMCAuthorities::Import::SubmittedNameGetter.new(type_limit: 'personal').names

# personal names with strong matches
strong = personal.reject { |p| p.strong_matches.empty? }

# this count reflects the "submitted names found in more than one inst/source/coll"
# rather than the "unique 'authorized-form' names present in more than one inst/source/coll"
strong.count
personal.count

# View clustering
hsh = NCMCAuthorities::Names::Personal.cluster_hash
hsh.map { |k, v| [k, v.members.length] }.to_a.sort_by { |x| x[1] }


# Family names
test_results(allnames.family_names)


# Corporate names use a corpus of trigrams. So, we're not comparing one name
# against another name in isolation, the comparison takes into account the
# term frequencies in the corpus.

# get only corporate names
corporate = allnames.corporate_names

# populate solr with a corpus of corporate name trigrams, like:
#   NCMCAuthorities::Names::Corporate.solr.add_docs(corporate)
# but if the corpus should include names of unknown-type:
unknown = allnames.unknown_type_names
NCMCAuthorities::Names::Corporate.solr.add_docs(
  corporate, unknown.map(&:corporate)
)

# write test results for corporate names
# (unknown-type names are included in the results for each corporate name when
#   applicable, but we're not writing results for each unknown-type name)
test_results(corporate)


# like corporate names, this uses a trigram corpus (but a separate corpus / solr collection)
meeting = allnames.meeting_names
NCMCAuthorities::Names::Meeting.solr.add_docs(
  meeting, unknown.map(&:meeting)
)
test_results(meeting)


# Unknown-type names

# We want to compare these against all of the other names.
# So we take the name as a personal name and compare it as a personal name against
#   personal names and other unknown names.
# Then we take it as a corporate name and compare it as a corporate name against
#   corporate names and other unknown names...
# ...same thing for family and meeting names.

# we've already imported unknown names in the above
#   unknown = NCMCAuthorities::Import::SubmittedNameGetter.new(type_limit: 'unknown').names

# we've also included those in the Corporate and Meeting corpora. Had we not, we would
# need to do that here.
test_results(unknown)



names = allnames.names
names.count

# Submitted names w/unique normalized form
names.reject { |n| n.ranking&.first&.category == :strong }.count

# Submitted names w/non-unique normalized form
names.select { |n| n.ranking&.first&.category == :strong }.count

# Normalized name forms that cluster multiple submitted names
names.reduce(0) { |sum, n| sum + n.unique_name_form_percent }

