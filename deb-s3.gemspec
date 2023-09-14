$:.unshift File.expand_path("../lib", __FILE__)
require "deb/s3"

Gem::Specification.new do |gem|
  gem.name        = "deb-s3-lock-fix"
  gem.version     = "#{Deb::S3::VERSION}.fix3"

  gem.author      = "Braeden Wolf & Ken Robertson"
  gem.email       = "braedenwolf@outlook.com & ken@invalidlogic.com"
  gem.homepage    = "https://github.com/braedenwolf/deb-s3-lock-fix"
  gem.summary     = "Easily create and manage an APT repository on S3 (with specific lock fix)."
  gem.description = "Fork of deb-s3 with a specific fix for locking. Original work by Ken Robertson."
  gem.license     = "MIT"
  gem.executables = "deb-s3"

  gem.files = Dir["**/*"].select { |d| d =~ %r{^(README|bin/|ext/|lib/)} }

  gem.required_ruby_version = '>= 2.7.0'

  gem.add_dependency "thor",    "~> 1"
  gem.add_dependency "aws-sdk-s3", "~> 1"
  gem.add_dependency "aws-sdk-dynamodb", "~> 1"
  gem.add_development_dependency "minitest", "~> 5"
  gem.add_development_dependency "rake", "~> 11"
end
