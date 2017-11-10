# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "archimate/dsl/version"

Gem::Specification.new do |spec|
  spec.name          = "archimate-dsl"
  spec.version       = Archimate::Dsl::VERSION
  spec.authors       = ["Mark Morga"]
  spec.email         = ["markmorga@gmail.com"]

  spec.summary       = 'ArchiMate models as a DSL'
  spec.description   = 'Enterprise Architecture as Code. Using ArchiMate from a text-based DSL.'
  spec.homepage      = "https://github.com/mmorga/archimate-dsl"

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "archimate", "~> 2.0"

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
end
