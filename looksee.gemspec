$:.unshift File.expand_path('lib', File.dirname(__FILE__))
require 'looksee/version'

Gem::Specification.new do |gem|
  gem.name = 'looksee'
  gem.version = Looksee::VERSION
  gem.authors = ["George Ogata"]
  gem.email = ["george.ogata@gmail.com"]
  gem.license = 'MIT'
  gem.date = Time.now.strftime('%Y-%m-%d')
  gem.summary = "Supercharged method introspection in IRB."
  gem.homepage = 'http://github.com/oggy/looksee'

  if RUBY_PLATFORM == 'java'
    gem.platform = Gem::Platform::CURRENT
  else
    gem.extensions = ["ext/extconf.rb"]
  end

  gem.extra_rdoc_files = ['CHANGELOG', 'LICENSE', 'README.markdown']
  gem.files = Dir['lib/**/*', 'ext/**/{*.c,*.h,*.rb}', 'CHANGELOG', 'LICENSE', 'Rakefile', 'README.markdown']
  gem.test_files = Dir["spec/**/*.rb"]
  gem.require_path = 'lib'

  gem.specification_version = 3
  gem.add_development_dependency 'bundler', '~> 1.3.5'
end
