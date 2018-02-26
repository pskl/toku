# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'toku/version'

Gem::Specification.new do |spec|
  spec.name          = "toku"
  spec.version       = Toku::VERSION
  spec.authors       = ["PSKL", "lordofthelake"]
  spec.email         = ["hello@pascal.cc"]

  spec.summary       = %q{Anonymize a database, fast}
  spec.description   = %q{Use row filters and column filters to make an anonymized copy of your production database.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'sequel'
  spec.add_dependency 'sequel_pg'
  spec.add_dependency 'faker'
  spec.add_dependency 'concurrent-ruby'

  spec.add_development_dependency "bundler", "~> 1.13"
  spec.add_development_dependency "rake", "~> 10.0"
end
