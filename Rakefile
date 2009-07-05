require 'rubygems'
gem 'hoe', '>= 2.1.0'
require 'hoe'
require 'fileutils'

require './lib/looksee/version'

Hoe.plugin :newgem
Hoe.plugin :cucumberfeatures

$hoe = Hoe.spec 'looksee' do
  self.developer 'George Ogata', 'george.ogata@gmail.com'
  self.rubyforge_name       = self.name # TODO this is default value
  # self.extra_deps         = [['activesupport','>= 2.0.2']]
  self.extra_dev_deps = [
    ['newgem', ">= #{::Newgem::VERSION}"],
    ['rspec', '>= 1.2.7'],
    ['mocha', '>= 0.9.5'],
  ]
end

# Configure the clean and clobber tasks.
require 'rake/clean'
require 'rbconfig'
CLEAN.include('**/*.o')
CLOBBER.include("ext/looksee/looksee.#{Config::CONFIG['DLEXT']}")

require 'newgem/tasks' # loads /tasks/*.rake
Dir['tasks/**/*.rake'].each { |t| load t }

desc "Rebuild the gem from scratch."
task :regem => [:clobber, :gem]

# Force build before running specs.
Rake::Task['spec'].prerequisites << 'extconf:compile'

task :default => :spec
