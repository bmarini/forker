# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "forker/version"

Gem::Specification.new do |s|
  s.name        = "forker"
  s.version     = Forker::VERSION
  s.date        = "2010-09-27"
  s.summary     = "Fork your ruby code with confidence"
  s.email       = "bmarini@gmail.com"
  s.homepage    = "http://github.com/bmarini/forker"
  s.description = "Fork your ruby code with confidence"
  s.authors     = ["Ben Marini"]
  s.files       = Dir.glob("lib/**/*") + %w(README.md)
  s.add_dependency "SystemTimer", "~> 1.2" if RUBY_VERSION < "1.9"
  s.add_development_dependency "minitest", "~> 2.0.2"
end
