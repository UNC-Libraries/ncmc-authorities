module NCMCAuthorities
  module Import
    class SubmittedNameGetter
      attr_reader :ct
      attr_reader :names
      attr_reader :uniq_names
      attr_reader :columns
      attr_reader :blank_names

      def initialize(type_limit: nil)
        #Dir.chdir('data/instdata')
        raw_files = Dir.glob(File.join(__dir__, '..', '..', 'data', 'instdata', '*')).reject { |filename| filename.split('/').last =~ /^(ORIG|test)/ }
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

            name = Names::SubmittedName.factory(row, file, id_counter, type_limit: type_limit)
            @names << name if name
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

      def personal_names
        @names.select(&:personal?)
      end

      def family_names
        @names.select(&:family?)
      end

      def corporate_names
        @names.select(&:corporate?)
      end

      def meeting_names
        @names.select(&:meeting?)
      end

      def unknown_type_names
        @names.select(&:unknown_type?)
      end
    end
  end
end
