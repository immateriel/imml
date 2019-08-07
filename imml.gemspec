# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'imml/version'

Gem::Specification.new do |spec|
  spec.name          = "imml"
  spec.version       = IMML::VERSION
  spec.authors       = ["julbouln"]
  spec.email         = ["jboulnois@immateriel.fr"]

  spec.summary       = %q{immat\u{e9}riel.fr IMML parser/writer}
  spec.description   = %q{immat\u{e9}riel.fr IMML parser/writer}
  spec.homepage      = "http://www.immateriel.fr"

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

  spec.add_development_dependency "bundler", "~> 1.14"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "minitest", "~> 5.0"
  spec.add_development_dependency "shoulda"

  spec.add_dependency 'nokogiri'
  spec.add_dependency 'levenshtein-ffi'
  spec.add_dependency 'posix-spawn'
end

