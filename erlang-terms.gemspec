# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'erlang/terms/version'

Gem::Specification.new do |spec|
  spec.name          = "erlang-terms"
  spec.version       = Erlang::Terms::VERSION
  spec.authors       = ["Andrew Bennett"]
  spec.email         = ["andrew@pagodabox.com"]
  spec.description   = %q{Includes simple classes that represent Erlang's export, list, pid, string, and tuple.}
  spec.summary       = %q{Erlang terms represented in Ruby}
  spec.homepage      = "https://github.com/potatosalad/erlang-terms"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
end
