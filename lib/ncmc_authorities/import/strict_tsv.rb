module NCMCAuthorities
  module Import
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
            fields = fields.map { |field| field.strip.squeeze(' ') }
            field_hash = Hash[@headers.zip(fields)]
            yield field_hash
          end
        end
      end
    end
  end
end
