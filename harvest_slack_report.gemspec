# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'harvest_slack_report/version'

Gem::Specification.new do |spec|
  spec.name          = "harvest_slack_report"
  spec.version       = HarvestSlackReport::VERSION
  spec.authors       = ["Matthew Ford"]
  spec.email         = ["matt@bitzesty.com"]

  spec.summary       = %q{Reporting Harvest data to Slack}
  spec.description   = %q{Reporting Harvest data to Slack}
  spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
end
