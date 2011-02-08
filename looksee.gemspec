$:.unshift File.expand_path('lib', File.dirname(__FILE__))
require 'looksee/version'

Gem::Specification.new do |s|
  s.name = 'looksee'
  s.version = Looksee::VERSION
  s.authors = ["George Ogata"]
  s.email = ["george.ogata@gmail.com"]
  s.date = Date.today.strftime('%Y-%m-%d')
  s.summary = "Inspect method lookup paths in ways not possible in plain ruby."
  s.description = "Inspect method lookup paths in ways not possible in plain ruby."
  s.homepage = 'http://github.com/oggy/looksee'
  s.platform = Gem::Platform::CURRENT if RUBY_PLATFORM == 'java'

  s.extensions = ["ext/mri/extconf.rb"] unless RUBY_PLATFORM == 'java'
  s.extra_rdoc_files = ['CHANGELOG', 'LICENSE', 'README.markdown']
  s.files = Dir["{doc,ext,lib}/**/*", 'CHANGELOG', 'LICENSE', 'Rakefile', 'README.markdown']
  s.test_files = Dir["spec/**/*"]
  s.require_path = 'lib'

  s.specification_version = 3
  s.add_development_dependency 'ritual', '>= 0.2.0'
  s.add_development_dependency 'rspec', '>= 2.0.0'
  s.add_development_dependency 'mocha'
end
