module NCMCAuthorities
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
end
