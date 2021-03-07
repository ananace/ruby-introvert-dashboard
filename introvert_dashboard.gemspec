# frozen_string_literal: true

require_relative 'lib/introvert-dashboard/version'

Gem::Specification.new do |spec|
  spec.name          = 'introvert_dashboard'
  spec.version       = IntrovertDashboard::VERSION
  spec.authors       = ['Alexander Olofsson']
  spec.email         = ['ace@haxalot.com']

  spec.summary       = 'A dashboard page'
  # spec.description   = %q{TODO: Write a longer description or delete this line.}
  # spec.homepage      = "TODO: Put your gem's website or public repo URL here."
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.3.0")

  # spec.metadata["homepage_uri"] = spec.homepage
  # spec.metadata["source_code_uri"] = "TODO: Put your gem's public repo URL here."
  # spec.metadata["changelog_uri"] = "TODO: Put your gem's CHANGELOG.md URL here."

  spec.files         = Dir['{bin,lib}/**/*']
  spec.require_paths = ['lib']

  spec.add_dependency 'concurrent-ruby'
  spec.add_dependency 'nokogiri'
  spec.add_dependency 'sinatra'
  spec.add_dependency 'thin'

  # For the Sinatra::Reloader
  spec.add_development_dependency 'sinatra-contrib'
end
