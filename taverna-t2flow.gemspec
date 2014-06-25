# -*- encoding: utf-8 -*-

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 't2flow/version'

Gem::Specification.new do |spec|
  spec.name = "taverna-t2flow"
  spec.version = T2Flow::VERSION
  spec.authors = ["Finn Bacall", "Robert Haines", "David Withers", "Mannie Tagarira", "Don Cruickshank"]
  spec.email = ["support@mygrid.org.uk"]

  spec.summary = "Parse Taverna 2 workflows."
  spec.description = %q{This gem enables parsing of Taverna 2 workflows (.t2flow).
  An example use would be the diagram generation for the model representing
  Taverna 2 workflows, as used in myExperiment.}

  spec.homepage = "http://www.taverna.org.uk/"
  spec.licenses = ["BSD-3-Clause"]
  spec.rdoc_options = ["-N", "--tab-width=2", "--main=README.rdoc"]
  spec.rubygems_version = "2.2.2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})

  spec.require_paths = ["lib"]
  spec.extra_rdoc_files = [
    "CHANGES.rdoc",
    "LICENCE",
    "README.rdoc"
  ]

  spec.add_development_dependency "rake"
  spec.add_development_dependency "coveralls"
  #spec.add_development_dependency "rdoc", "~> 3.9.4"
  spec.add_development_dependency "minitest", "~> 5.3"
  spec.add_development_dependency "rubocop", "~> 0.24.0"
  spec.add_runtime_dependency "mime-types", "~> 2.3"
  spec.add_runtime_dependency "libxml-ruby", "~> 2.7.0"
  spec.add_runtime_dependency "rdf-turtle", "~> 1.1.4"
  #spec.add_runtime_dependency "rdf-n3", "~> 1.1.1"
end

