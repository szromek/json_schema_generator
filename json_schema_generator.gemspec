# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'json_schema_generator/version'

Gem::Specification.new do |spec|
  spec.name          = "json_schema_generator"
  spec.version       = JsonSchemaGenerator::VERSION
  spec.authors       = ["mazikwyry", "szromek"]
  spec.email         = ["a.mazur@exlabs.co.uk", "k.szromek@exlabs.pl"]

  spec.summary       = %q{Write a short summary, because Rubygems requires one.}
  spec.description   = %q{sdfsdite a longer description or delete this line.}

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-nav"
end
