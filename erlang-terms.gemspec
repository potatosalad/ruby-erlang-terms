# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'erlang/terms/version'

Gem::Specification.new do |spec|
  spec.name          = "erlang-terms"
  spec.version       = Erlang::Terms::VERSION
  spec.authors       = ["Andrew Bennett"]
  spec.email         = ["andrew@pixid.com"]

  spec.description   = <<-EOF
    Includes simple classes that represent Erlang's atom, binary, bitstring,
    compressed, export, function, list, map, nil, pid, port, reference,
    string, and tuple.
  EOF
  spec.summary       = %q{Erlang terms represented in Ruby}
  spec.homepage      = "https://github.com/potatosalad/ruby-erlang-terms"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.15"
  spec.add_development_dependency "rake", "~> 12.0"
  spec.add_development_dependency "minitest"
end
