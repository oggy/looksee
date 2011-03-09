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
  s.platform = Gem::Platform::CURRENT if RUBY_PLATFORM == 'java'

  ruby_engine = Object.const_defined?(:RUBY_ENGINE) ? RUBY_ENGINE : 'mri'
  extension = ruby_engine == 'ruby' ? 'mri' : ruby_engine
  s.extensions = ["ext/#{extension}/extconf.rb"] unless extension == 'jruby'
  s.extra_rdoc_files = ['CHANGELOG', 'LICENSE', 'README.markdown']
  s.files = Dir['lib/**/*', 'ext/**/{Makefile,*.c,*.h,*.rb}', 'CHANGELOG', 'LICENSE', 'Rakefile', 'README.markdown']
  s.test_files = Dir["spec/**/*.rb"]
  s.require_path = 'lib'

  s.specification_version = 3
  s.add_development_dependency 'ritual', '>= 0.2.0'
  s.add_development_dependency 'rspec', '>= 2.0.0'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'wirble'
end
