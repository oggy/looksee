%w[rubygems rake rake/clean fileutils newgem rubigen].each { |f| require f }
require File.dirname(__FILE__) + '/lib/looksee/version'

$hoe = Hoe.new('looksee', Looksee::VERSION) do |p|
  p.developer('George Ogata', 'george.ogata@gmail.com')
  p.changes              = p.paragraphs_of("History.txt", 0..1).join("\n\n")
  #p.post_install_message = 'PostInstall.txt'
  p.rubyforge_name       = p.name
  #p.extra_deps           = [['gemname', 'version']]
  p.extra_dev_deps = [
    ['newgem', ">= #{::Newgem::VERSION}"],
    ['rspec', '1.2.0'],
    ['mocha', '0.9.5'],
  ]

  p.clean_globs |= %w[**/.DS_Store tmp *.log]
  path = (p.rubyforge_name == p.name) ? p.rubyforge_name : "\#{p.rubyforge_name}/\#{p.name}"
  p.remote_rdoc_dir = File.join(path.gsub(/^#{p.rubyforge_name}\/?/,''), 'rdoc')
  p.rsync_args = '-av --delete --ignore-errors'
end

# Configure the clean and clobber tasks.
require 'rbconfig'
CLEAN.include('**/*.o')
CLOBBER.include("ext/looksee/looksee.#{Config::CONFIG['DLEXT']}")

require 'newgem/tasks' # loads /tasks/*.rake
Dir['tasks/**/*.rake'].each { |t| load t }

task :default => :spec

require 'spec/rake/spectask'
Spec::Rake::SpecTask.new(:spec => :compile) do |t|
  t.libs << 'lib' << 'spec'
end

task :regem do
  rm_f FileList['pkg/*.gem']
  Rake::Task['gem'].invoke
end
