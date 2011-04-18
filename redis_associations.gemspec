# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "redis_associations/version"

Gem::Specification.new do |s|
  s.name        = "redis_associations"
  s.version     = RedisAssociations::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Maciej Ochałek"]
  s.email       = ["ohaleckATgmail.com"]
  s.homepage    = ""
  s.summary     = %q{ActiveRecord model associations in Redis}
  s.description = %q{Denormalizes and improves the performance of associations between ActiveRecord models by storing them in Redis.}

  s.add_dependency "redis"
  s.add_dependency "SystemTimer" # required by redis to work well
  s.add_development_dependency "mocha"


  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
