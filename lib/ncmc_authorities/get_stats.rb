require_relative 'names'

#Dir.chdir('lib/data/instdata')
allnames = SubmittedNameGetter.new

puts "\n\n\nTOTAL NAMES SUBMITTED: #{allnames.ct}"
puts "\n\n\nTOTAL NAMES SUBMITTED (DEDUPLICATED): #{allnames.uniq_names.length}"

#puts allnames.columns
#allnames.report_blank_names

puts "\n\n-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
puts "OVERLAP ANALYSIS"
puts "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
 norm_names = NormNameGetter.new(allnames.uniq_names).names
 puts "\n\n---TOTAL NORMALIZED NAME FORMS---"
 puts "#{norm_names.length} (of #{allnames.ct} total names submitted)"

 recon = norm_names.select { |n| n.reconciled == true }
 puts "Count of reconciled: #{recon.length}"

 puts "\n\n---NORMALIZED NAME FORMS THAT CLUSTER MORE THAN ONE SUBMITTED NAME---"
 multi = norm_names.extract_multi_names
 puts "COUNT: #{multi.length}"
 multi.put_examples(5)
 puts "MAX NAMES: #{multi.max_names} -- MIN NAMES: #{multi.min_names}"

 max =  multi.select { |nn| nn.name_ct == multi.max_names }.first
 puts max.norm_name
 puts max.collections

 puts "\n\n---NORMALIZED NAME FORMS THAT DON'T CLUSTER MORE THAN ONE SUBMITTED NAME (unique names)---"
 single = norm_names.extract_single_names
 puts "COUNT: #{single.length}"
 single.put_examples(5)


 puts "\n\n---NAMES USED AT MULTIPLE INSTITUTIONS---"
 multi_inst = norm_names.extract_multi_inst_names
 puts "COUNT: #{multi_inst.length}"
 multi_inst.put_examples(5)


 recon = multi_inst.select { |n| n.reconciled == true }
 puts "Count of reconciled: #{recon.length}"

 # puts "\n\n---NAMES USED MULTIPLE TIMES AT THE SAME INSTITUTION---"
 # multi_in_inst = norm_names.extract_multi_in_inst_names
 # puts "COUNT: #{multi_in_inst.length}"
 # multi_in_inst.put_examples(5)

 # puts "\n\n---NAMES USED IN MULTIPLE SYSTEMS AT THE SAME INSTITUTION---"
 # multi_in_sys = norm_names.extract_multi_in_sys_names
 # puts "COUNT: #{multi_in_sys.length}"
 # multi_in_sys.put_examples(5)

 # puts "\n\n---NAMES USED IN MULTIPLE COLLECTIONS AT THE SAME INSTITUTION---"
 # multi_in_coll = norm_names.extract_multi_in_coll_names
 # puts "COUNT: #{multi_in_coll.length}"
 # multi_in_coll.put_examples(5)

#  diff = NormNames.new
#  ( multi_in_inst - multi_in_sys ).each { |e| diff << e }
#  puts "COUNT: #{diff.length}"
#  diff.put_examples(5)

#by_norm_name.value_details_over_threshold(1)

# puts "\n\n---NORMALIZED NAMES THAT COLLAPSE ACROSS SYSTEMS WITHIN INSTITUTIONS---"
# multi_sys = by_norm_name.multi_system
# puts "COUNT: #{multi_sys.keys.length}"
# puts "EXAMPLES:"
# multi_sys.keys[0..4].each do |k|
#   nd = multi_sys[k]
#   norm_name = k
#   insts = nd[:inst].join(';')
#    nd[:names].each { |n| puts "#{norm_name}\t#{insts}\t#{n[:name]}\t#{n[:institution]}\t#{n[:source_system]}\t#{n[:collection]}" }
#  end

# puts "\n\n-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
# puts "OVERALL/TOTAL STATS - names submitted (not normalized/collapsed)"
# puts "-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-"
# by_inst = NamesByFieldValue.new(names.data, :institution)
# puts "\n\n---TOTAL NAMES PER INSTITUTION---"
# by_inst.counts_by_value

# by_sys = NamesByFieldValue.new(names.data, :source_system_full)
# puts "\n\n---TOTAL NAMES PER INSTITUTION SOURCE SYSTEM---"
# by_sys.counts_by_value

# by_coll = NamesByFieldValue.new(names.data, :coll_full)
# puts "\n\n---TOTAL NAMES PER INSTITUTION SOURCE SYSTEM COLLECTION---"
# by_coll.counts_by_value

# by_type = NamesByFieldValue.new(names.data, :name_type)
# puts "\n\n---TOTAL NAMES PER NAME TYPE---"
# by_type.counts_by_value

# if by_type.hash.has_key?('unknown')
#   type_by_coll = NamesByFieldValue.new(by_type.hash['unknown'], :coll_full)
#   puts "\n\n---NAMES LACKING TYPE PER COLLECTION---"
#   type_by_coll.counts_by_value
# end




# by_variants = NamesByFieldPresence.new(names.data, :variants)
# puts "\n\n---NAMES BY HAVING VARIANTS---"
# by_variants.counts_by_value

# by_rel = NamesByFieldPresence.new(names.data, :role_or_relator)
# puts "\n\n---NAMES BY HAVING ROLE/RELATOR---"
# by_rel.counts_by_value
# #by_rel.sample_details_by_value('has_role_or_relator', 5, [:name, by_rel.field, :name_id])

# rel_by_coll = NamesByFieldValue.new(by_rel.hash['has_role_or_relator'], :coll_full)
# puts "\n\n---NAMES WITH RELATOR/ROLE PER COLLECTION---"
# rel_by_coll.counts_by_value
# #rel_by_coll.sample_details_by_value('unch-cdr-', 10, [:name, by_rel.field, :name_id])

# by_lcnaf_uri = NamesByFieldPresence.new(names.data, :lcnaf_uri)
# puts "\n\n---NAMES BY HAVING LCNAF URI---"
# by_lcnaf_uri.counts_by_value
# #by_lcnaf_uri.sample_details_by_value('has_lcnaf_uri', 5, [:name, by_lcnaf_uri.field, :name_id])

# by_lcnaf_string = NamesByFieldPresence.new(names.data, :lcnaf_string)
# puts "\n\n---NAMES BY HAVING LCNAF STRING---"
# by_lcnaf_string.counts_by_value


# by_lc_reconciled = NamesByFieldPresence.new(names.data, :lc_reconciled)
# puts "\n\n---NAMES BY HAVING SOME TYPE OF LCNAF RECONCILIATION---"
# by_lc_reconciled.counts_by_value
