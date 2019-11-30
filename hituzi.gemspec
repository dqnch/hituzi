# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'hituzi/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |spec|
  spec.name        = 'hituzi'
  spec.version     = Hituzi::VERSION
  spec.authors     = ['kawamura.hryk']
  spec.email       = ['kawamura.hryk@gmail.com']
  spec.homepage    = 'https://github.com/dqnch/hituzi'
  spec.summary     = 'Hituzi is an Artificial non-Intelligence.'
  spec.description = 'Hituzi is an Artificial non-Intelligence.'
  spec.license     = 'MIT'

  spec.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  spec.add_dependency 'rails', '>= 5.1'

  spec.add_development_dependency 'sqlite3'
  spec.add_development_dependency 'rspec-rails'
end
