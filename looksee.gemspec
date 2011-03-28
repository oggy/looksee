$:.unshift File.expand_path('lib', File.dirname(__FILE__))
require 'looksee/version'

Gem::Specification.new do |s|
  s.name = 'looksee'
  s.version = Looksee::VERSION
  s.authors = ["George Ogata"]
  s.email = ["george.ogata@gmail.com"]
  s.date = Time.now.strftime('%Y-%m-%d')
  s.summary = "Supercharged method introspection in IRB."
  s.homepage = 'http://github.com/oggy/looksee'

  if RUBY_PLATFORM == 'java'
    s.platform = Gem::Platform::CURRENT
  else
    s.extensions = ["ext/extconf.rb"]
  end

  s.extra_rdoc_files = ['CHANGELOG', 'LICENSE', 'README.markdown']
  s.files = Dir['lib/**/*', 'ext/**/{*.c,*.h,*.rb}', 'CHANGELOG', 'LICENSE', 'Rakefile', 'README.markdown']
  s.test_files = Dir["spec/**/*.rb"]
  s.require_path = 'lib'

  s.specification_version = 3
  s.add_development_dependency 'ritual', '0.3.0'
  s.add_development_dependency 'rspec', '2.5.0'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'wirble'
end
