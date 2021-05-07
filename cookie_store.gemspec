require_relative 'lib/cookie_store/version'

Gem::Specification.new do |s|
  s.name        = "cookie_store"
  s.version     = CookieStore::VERSION
  s.authors     = ["Jon Bracy"]
  s.email       = ["jonbracy@gmail.com"]
  s.homepage    = "https://github.com/malomalo/cookie_store"
  s.summary     = %q{A Ruby library to handle client-side HTTP cookies}
  s.description = %q{A Ruby library to handle client-side HTTP cookies}

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths = ["lib"]

  s.add_runtime_dependency 'stream_parser', '>= 0.2'
  
  # Developoment 
  s.add_development_dependency 'rake'
  s.add_development_dependency 'byebug'
  # s.add_development_dependency 'rdoc'
  # s.add_development_dependency 'sdoc'
  s.add_development_dependency 'minitest'
  s.add_development_dependency 'minitest-reporters'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'faker'
  s.add_development_dependency 'webmock'
  s.add_development_dependency 'activesupport'
  s.add_development_dependency 'simplecov'
end
