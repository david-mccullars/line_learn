# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'line_learn/version'

Gem::Specification.new do |spec|
  spec.name          = "line_learn"
  spec.version       = LineLearn::VERSION
  spec.authors       = ["David McCullars"]
  spec.email         = ["dmccullars@bloomfire.com"]
  spec.description   = %q{Gameified tool for learning lines}
  spec.summary       = %q{Gameified tool for learning lines}
  spec.homepage      = "https://github.com/david-mccullars/line_learn"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_runtime_dependency 'highline', '~> 1.6'
  spec.add_runtime_dependency 'diff-lcs', '~> 1.2'
end
