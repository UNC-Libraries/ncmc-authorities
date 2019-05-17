require 'ncmc_authorities'

module NCMCAuthorities
  class CommandLine < Thor

    map %w[--version -v] => :__version

    desc '--version, -v', 'print the version'
    def __version
      puts "ncmc_authorities version #{NCMCAuthorities::VERSION}, installed #{File.mtime(__FILE__)}"
    end

    desc 'get_mode', 'get mode'
    def get_mode
     puts LCNAF::return_mode
    end

    desc 'list_fields', 'List all available Solr fields'
    def list_fields
      data_dir = File.expand_path('../data',File.dirname(__FILE__))
      field_config = "#{data_dir}/field_config.yml"
      config = YAML.load_file(field_config)
      fields = config['extract'] + config['available']
      puts fields.flatten.sort
    end
  end
end
