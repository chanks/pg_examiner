# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'pg_examiner/version'

Gem::Specification.new do |spec|
  spec.name          = 'pg_examiner'
  spec.version       = PGExaminer::VERSION
  spec.authors       = ["Chris Hanks"]
  spec.email         = ["christopher.m.hanks@gmail.com"]
  spec.summary       = %q{Parse the schemas of Postgres databases in detail}
  spec.description   = %q{Examine and compare the tables, columns, constraints and other information that makes up the schema of a PG database}
  spec.homepage      = 'https://github.com/chanks/pg_examiner'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.6'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'pry'
end
