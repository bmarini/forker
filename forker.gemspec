Gem::Specification.new do |s|
  s.name        = "forker"
  s.version     = "1.0.1"
  s.date        = "2010-09-27"
  s.summary     = "Fork your ruby code with confidence"
  s.email       = "bmarini@gmail.com"
  s.homepage    = "http://github.com/bmarini/forker"
  s.description = "Fork your ruby code with confidence"
  s.authors     = ["Ben Marini"]
  s.files       = Dir.glob("lib/**/*") + %w(README.md)
  s.add_dependency "SystemTimer", "~> 1.2"
end
