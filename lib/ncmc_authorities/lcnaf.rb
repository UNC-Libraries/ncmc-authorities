require 'ncmc_authorities'

module NCMCAuthorities
  module LCNAF
=begin
Assumes you have 
- downloaded the LC Name Authority File (LCNAF) (MADS/RDF and SKOS/RDF)
  file in nt format from http://id.loc.gov/static/data/authoritiesnames.nt.both.zip
  and have unzipped it such that the authoritiesnames.nt.both file is in
  lib/data/lcdata
- run the following commands on the file:
  --to extract the ids of personal names--
  grep -F "#type> <http://www.loc.gov/mads/rdf/v1#PersonalName> ." authoritiesnames.nt.both | sed -n '/^<http:\/\/id\.loc\.gov\/authorities\/names/p' > pn_ids.txt
  --to extract the ids of corporate names--
  grep -F "#type> <http://www.loc.gov/mads/rdf/v1#CorporateName> ." authoritiesnames.nt.both | sed -n '/^<http:\/\/id\.loc\.gov\/authorities\/names/p' > cn_ids.txt
  --to extract the ids of family names--
  grep -F "#type> <http://www.loc.gov/mads/rdf/v1#FamilyName> ." authoritiesnames.nt.both | sed -n '/^<http:\/\/id\.loc\.gov\/authorities\/names/p' > fn_ids.txt
=end

  MODE = 'test'
  
  case MODE
  when 'prod'
    af = 'data/lcdata/authoritiesnames.nt.both'
  when 'test'
    af = 'data/lcdata/smallsample.nt'
  end

  def return_mode
    MODE
  end

  extend self
  end
end
