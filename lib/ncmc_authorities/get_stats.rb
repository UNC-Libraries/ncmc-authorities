# encoding: utf-8

require 'active_support/inflector'
require 'pp'

class StrictTsv
  attr_reader :filepath
  attr_reader :headers
  
  def initialize(filepath)
    @filepath = filepath
  end

  def parse
    File.open(filepath) do |f|
      # the weird sub at the end gets rid of Excel BOM as per:
      # https://estl.tech/of-ruby-and-hidden-csv-characters-ef482c679b35
      @headers = f.gets.downcase.strip.split("\t").map { |hdr| hdr.sub("\xEF\xBB\xBF", '').to_sym }
      f.each do |line|
        line.gsub!('"', '') #strips out double quotes
        fields = line.split("\t")
        fields = fields.map { |f| f.strip.squeeze(' ') }
        field_hash = Hash[@headers.zip(fields)]
        yield field_hash
      end
    end
  end
end

class SubmittedName
  attr_reader :name
  attr_reader :norm_name
  attr_reader :type
  attr_reader :variants
  attr_reader :relator
  attr_reader :lcnaf_string
  attr_reader :lcnaf_uri
  attr_reader :institution
  attr_reader :source_system
  attr_reader :collection
  attr_reader :source_system_full
  attr_reader :coll_full
  attr_reader :source_file
  attr_reader :name_id
  attr_reader :lc_reconciled

  # initialized with:
  #  - hash of name data from tsv row
  #  - name of source file
  #  - count of source file row
  def initialize(nh, file, ct)
    @name = nh[:name]
    @norm_name = normalize_name(@name)
    @type = clean_name_type(nh[:name_type])
    @variants = nh[:variants].split(';;;').map { |v| v.strip } if  nh[:variants]
    @relator = nh[:role_or_relator]
    @lcnaf_string = nh[:lcnaf_string]
    @lcnaf_uri = nh[:lcnaf_uri]
    @institution = nh[:institution].upcase
    @source_system = nh[:source_system].downcase
    @source_system_full = "#{@institution}-#{@source_system}"
    if (nh[:collection].nil? || nh[:collection].empty?)
      @collection = 'none'
    else
      @collection = nh[:collection]
    end
    @coll_full = "#{@source_system_full}-#{@collection}"
    @source_file = file
    @name_id = "#{file}#{ct}"
    @lc_reconciled = false
    @lc_reconciled = true unless (@lcnaf_uri.nil? || @lcnaf_uri.empty?)
    @lc_reconciled = true unless (@lcnaf_string.nil? || @lcnaf_string.empty?)
  end

  private
  def normalize_name(name)
    name = name.downcase
    name = name.unicode_normalize(:nfkd).gsub(/\p{Mn}/, '')
    name = name.parameterize.gsub('-', ' ')
  end

  def clean_name_type(value)
    case value
    when 'agent_family'
      type = 'family'
    when 'conference'
      type = 'meeting'
    when 'person'
      type = 'personal'
    when ''
      type = 'unknown'
    else
      type = value
    end
    type.downcase
  end
end

class SubmittedNameGetter
  attr_reader :ct
  attr_reader :names
  attr_reader :uniq_names
  attr_reader :columns
  attr_reader :blank_names

  def initialize
    Dir.chdir('data/instdata')
    raw_files = Dir.glob('*').reject { |filename| filename =~ /^(ORIG|test)/ }
    #raw_files = ['test.tsv']

    @names = []
    @columns = []
    @blank_names = {}
    
    raw_files.each do |file|
      id_counter = 2
      tsv = StrictTsv.new(file)

      @blank_names[file] = []
      tsv.parse do |row|

        if row[:name] == ''
          @blank_names[file] << id_counter
          next
        end
    
        @names << SubmittedName.new(row, file, id_counter)
        @columns << row.keys if id_counter == 2
        id_counter += 1
      end
    end

    uniquify
    @ct = @names.length
    @columns = @columns.flatten.uniq
  end

  def uniquify
    h = {}
    @names.each do |n|
      nid = "#{n.name}-#{n.coll_full}-#{n.type}"
      nid << n.relator if n.relator
      nid << n.variants.join if n.variants
      nid << n.lcnaf_string if n.lcnaf_string
      nid << n.lcnaf_uri if n.lcnaf_uri
      h[nid] = n
    end
    @uniq_names = h.values
  end
    
  def report_blank_names
    puts "\n\nBLANK NAME ROWS"
    @blank_names.each { |k, v| puts "#{k}:\t #{v.length}" }
  end
end

class NameHash
  attr_reader :hash
  attr_reader :keys
  attr_reader :field
  
  def counts_by_value
    sorted = @hash.sort_by { |k, v| v.length * -1 }
    sorted.each { |field, names| puts "#{field}: #{names.length}" }
  end

  def value_details_under_threshold(ct)
    h = @hash.select { |k, v| v.length < ct }
    h.each { |k, v| value_details(k) }
  end
  
  def value_details_over_threshold(ct)
    h = @hash.select { |k, v| v.length > ct }
    h.each { |k, v| value_details(k) }
  end
  
  def value_details(value)
    @hash[value].each do |name|
      puts "#{value}\t#{name[:name_id]}\t#{name[:name]}\t#{name[:norm_name]}"  
    end
  end

  def sample_details_by_value(key, size, array_of_detail_fields)
    sample = @hash[key][0..size]
    sample.each do |name|
      pval = []
      array_of_detail_fields.each do |df|
        val = name[df]
        pval << "#{df.to_s.upcase}: #{val}"
      end
      puts pval.join("\t")
    end
  end
end

class NamesByFieldValue < NameHash
  def initialize(all_names, field)
    @field = field
    @hash = populate_new_hash(all_names, field)
    @keys = @hash.keys
  end

  private
  def populate_new_hash(names, field)
    h = {}
    names.each do |name_hash|
      field_val = name_hash[field]
      if h.has_key?(field_val)
        h[field_val] << name_hash
      else
        h[field_val] = [name_hash]
      end
    end
    h
  end
end

class NamesByFieldPresence < NameHash
  def initialize(all_names, field)
    @field = field
    @hash = populate_new_hash(all_names, field)
    @keys = @hash.keys
  end

  private
  def populate_new_hash(names, field)
    h = {}
    h["has_#{field}"] = []
    h["no_#{field}"] = []
    
    names.each do |name_hash|
      field_val = name_hash[field]
      if field_val.nil?
        h["no_#{field}"] << name_hash
      elsif field_val.empty?
        h["no_#{field}"] << name_hash
      else
        h["has_#{field}"] << name_hash
      end
    end
    h
  end
end

class NormName
  attr_reader :norm_name
  attr_reader :institutions
  attr_reader :inst_ct
  attr_reader :systems
  attr_reader :collections
  attr_reader :names
  attr_reader :name_ct
  attr_reader :multi
  attr_reader :multi_inst #name was submitted by more than one institution
  attr_reader :multi_sys #name submitted by the same institution from >1 system
  attr_reader :multi_coll #name submitted by the same institution from >1 collection in the same system
  attr_reader :multi_in_inst #name was submitted multiple times by the same institution
  attr_reader :multi_in_sys #name submitted multiple times by the same institution from the same system
  attr_reader :multi_in_coll #name submitted multiple times by the same institution from the same  collection in the same system
  attr_reader :reconciled #at least one form of name clustered under norm form is reconciled to lcnaf

  def initialize(normname, nnhash)
    @norm_name = normname
    @institutions = nnhash[:inst].sort
    @inst_ct = @institutions.uniq.length
    @systems = nnhash[:sys].sort
    @collections = nnhash[:coll].sort
    @names = nnhash[:names]
    @name_ct = @names.length
    @multi = true if @name_ct > 1
    @multi_inst = true if @multi && @inst_ct > 1
    @multi_sys = true if @multi && is_multi?(@systems.uniq)
    @multi_coll = true if @multi && is_multi?(@collections.uniq)
    @multi_in_inst = true if @multi && is_multi?(@institutions)
    @multi_in_sys = true if @multi && is_multi?(@systems)
    @multi_in_coll = true if @multi && is_multi?(@collections)
    @reconciled = true if reconciled?
  end

  private
  def reconciled?
    strings = @names.map{ |n| n.lcnaf_string }.reject{ |e| e.empty? }
    uris = @names.map{ |n| n.lcnaf_uri }.reject{ |e| e.empty? }
    recondata = strings + uris
    return true if recondata.flatten.length > 0
  end
  
  def is_multi?(array)
    h = {}
    array.each do |e|
      h[e] = 0
    end

    array.each do |e|
      h[e] += 1
    end
    
    hm = h.select { |val, ct| ct > 1 }
    true if hm.length > 0
  end
end

class NormNames < Array
  def put_examples(number)
    puts "EXAMPLES:"
    iend = number - 1
    self[0..iend].each do |nn|
      insts = nn.institutions.uniq.join(';')
      nn.names.each { |n| puts "#{nn.norm_name}\t#{insts}\t#{n.name}\t#{n.institution}\t#{n.source_system_full}\t#{n.coll_full}" }
    end
  end

  def max_names
    build_name_count_hash.pop
  end

  def min_names
    build_name_count_hash.shift
  end
  
  def extract_multi_names
    nn = NormNames.new
    self.select { |n| n.multi == true }.each { |n| nn << n }
    nn
  end

    def extract_single_names
    nn = NormNames.new
    self.select { |n| n.name_ct == 1 }.each { |n| nn << n }
    nn
  end

  def extract_multi_inst_names
    nn = NormNames.new
    self.select { |n| n.multi_inst == true }.each { |n| nn << n }
    nn
  end

  def extract_multi_sys_names
    nn = NormNames.new
    self.select { |n| n.multi_sys == true }.each { |n| nn << n }
    nn
  end

  def extract_multi_coll_names
    nn = NormNames.new
    self.select { |n| n.multi_coll == true }.each { |n| nn << n }
    nn
  end

  def extract_multi_in_inst_names
    nn = NormNames.new
    self.select { |n| n.multi_in_inst == true }.each { |n| nn << n }
    nn
  end

  def extract_multi_in_sys_names
    nn = NormNames.new
    self.select { |n| n.multi_in_sys == true }.each { |n| nn << n }
    nn
  end

  def extract_multi_in_coll_names
    nn = NormNames.new
    self.select { |n| n.multi_in_coll == true }.each { |n| nn << n }
    nn
  end

  private
    def build_name_count_hash
    h = {}
    self.each { |nn| h[nn.name_ct] = nil }
    cts = h.keys.sort
    cts
  end
end

class NormNameGetter
  attr_reader :names
  
  def initialize(name_array)
    @names = get_norm_names(name_array)
  end


  def get_norm_names(name_array)
    norm_names = NormNames.new
    norm_name_hash = build_norm_name_hash(name_array)
    norm_name_hash.each { |nn, nd| norm_names << NormName.new(nn, nd) }
    norm_names
  end

  def build_norm_name_hash(name_array)
    h = {}
    # build first level: norm_name
    name_array.each { |n| h[n.norm_name] = {:inst => [],
                                         :sys => [],
                                         :coll => [],
                                         :names => []} }

    # build 2nd level: overlap info
    name_array.each do |n|
      h[n.norm_name][:inst] << n.institution
      h[n.norm_name][:sys] << n.source_system_full
      h[n.norm_name][:coll] << n.coll_full
      h[n.norm_name][:names] << n
    end

    h.each do |nn, nd|
      recon_names = nd[:names].select { |k, v| k == :lc_reconciled && v }
      nd[:lc_recon] = true if recon_names.length > 0
    end
    
    h
  end

end

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
