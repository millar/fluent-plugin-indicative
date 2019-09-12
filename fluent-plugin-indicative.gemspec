# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "fluent-plugin-indicative"
  s.version     = "0.1.3"
  s.authors     = ["Sam Millar"]
  s.email       = ["sam@millar.io"]
  s.homepage    = "https://github.com/millar/fluent-plugin-indicative"
  s.summary     = %q{Fluentd output plugin to send events to Indicative}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_development_dependency "rake"
  s.add_development_dependency "test-unit", ">= 3.1.0"
  s.add_development_dependency "webmock", ">= 3.6.0", "< 4"
  s.add_runtime_dependency "fluentd", ">= 0.14.15", "< 2"
end
