

# standard library helpers

# external helpers
require 'thor' #CommandLine interface

module NCMCAuthorities
  autoload :VERSION, 'ncmc_authorities/version'
  autoload :CommandLine, 'ncmc_authorities/command_line'
  autoload :LCNAF, 'ncmc_authorities/lcnaf'
end
