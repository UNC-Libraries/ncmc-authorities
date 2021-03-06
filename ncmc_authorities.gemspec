
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "ncmc_authorities/version"

Gem::Specification.new do |spec|
  spec.name          = "ncmc_authorities"
  spec.version       = NCMCAuthorities::VERSION
  spec.authors       = ["Kristina Spurgin"]
  spec.email         = ["kspurgin@email.unc.edu"]

  spec.summary       = %q{Tools to analyze and reconcile authority data collected for NCMC project.}
  spec.description   = %q{No fuller description available now}
  spec.homepage      = "https://github.com/"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 12.3", ">= 12.3.3"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_runtime_dependency 'activesupport', '~> 5.2'
  spec.add_runtime_dependency 'amatch', '~> 0.4.0'
  spec.add_runtime_dependency 'rspec', '~> 3.0'
  spec.add_runtime_dependency 'rsolr', '~> 2.2.1'
  spec.add_runtime_dependency 'text', '~> 1.3.1'
  spec.add_runtime_dependency 'trigram'
  spec.add_runtime_dependency 'thor', '~> 0.20.0'
  spec.add_runtime_dependency 'tf-idf-similarity'
  spec.add_runtime_dependency 'narray'
end
