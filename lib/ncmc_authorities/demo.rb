# load files
load 'lib/ncmc_authorities.rb'

# get all names with little/no deduping
allnames = NCMCAuthorities::Import::SubmittedNameGetter.new

d = allnames.names.select { |n| n.lcnaf_id }
d = allnames.names.select { |n| n.type == 'personal'  && !n.dates.empty? }
d = allnames.names.select { |n| n.type == 'personal'  && !n.variant_forename.empty? }


# count of names by type
allnames.names.group_by { |n| n.type }.map { |k, v| [k, v.length]}.to_h

# limit to personal names
personal = allnames.personal_names
personal.count

# you can also import only personal names by
#   personal = NCMCAuthorities::Import::SubmittedNameGetter.new(type_limit: 'personal').names

pname = personal.first
c = pname.blocks.first

# see matches that qualify as "strong" according to the criteria
#   in SubmittedName.strong_matches
pname.strong_matches

# write test results for personal names with matches
NCMCAuthorities::Export.export_matches('personal')

# personal names with strong matches
strong = personal.reject { |p| p.strong_matches.empty? }

# this count reflects the "submitted names found in more than one inst/source/coll"
# rather than the "unique 'authorized-form' names present in more than one inst/source/coll"
strong.count
personal.count

# View blocking
hsh = NCMCAuthorities::Names::Personal.block_hash
hsh.map { |k, v| [k, v.members.length] }.to_a.sort_by { |x| x[1] }

# Family names
NCMCAuthorities::Export.export_matches('family')

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
# (The command below includes adding the corporate/unknown docs to solr. We
# didn't need to do that separately above; nor will doing it above cause any
# problems with the below.)
NCMCAuthorities::Export.export_matches('corporate')

# like corporate names, this uses a trigram corpus (but a separate corpus / solr collection)
meeting = allnames.meeting_names
NCMCAuthorities::Names::Meeting.solr.add_docs(
  meeting, unknown.map(&:meeting)
)
NCMCAuthorities::Export.export_matches('meeting')

# Unknown-type names
#
# We want to compare these against all of the other names.
# So we take the name as a personal name and compare it as a personal name against
#   personal names and other unknown names.
# Then we take it as a corporate name and compare it as a corporate name against
#   corporate names and other unknown names...
# ...same thing for family and meeting names.
NCMCAuthorities::Export.export_matches('unknown_type')
