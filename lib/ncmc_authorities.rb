

# standard library helpers

# external helpers
require 'amatch'
require 'thor' #CommandLine interface
require 'text'
require 'trigram'

module NCMCAuthorities
  autoload :VERSION, 'ncmc_authorities/version'
  autoload :CommandLine, 'ncmc_authorities/command_line'
  autoload :LCNAF, 'ncmc_authorities/lcnaf'

  require_relative 'ncmc_authorities/solr.rb'
  require_relative 'ncmc_authorities/trigram.rb'

  require_relative 'ncmc_authorities/block'
  require_relative 'ncmc_authorities/match'
  require_relative 'ncmc_authorities/string_comparator'

  require_relative 'ncmc_authorities/names'

  require_relative 'ncmc_authorities/import'
  require_relative 'ncmc_authorities/export'
end
