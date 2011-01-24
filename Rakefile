require 'rubygems'
require 'fileutils'

$: << 'lib'
require 'looksee/version'

# Configure the clean and clobber tasks.
require 'rake/clean'
require 'rbconfig'
CLEAN.include('**/*.{o,class}')
CLOBBER.include('*.gem')

task :gem => ['ext:build_for_gem', 'clean'] do
  sh "gem build looksee.gemspec"
end

desc "Rebuild the gem from scratch."
task :regem => [:clobber, :gem]

# Force build before running specs.
Rake::Task['spec'].prerequisites << "ext:build"

task :default => :spec

namespace :ext do
  MRI_EXT = "lib/looksee/mri.#{Config::CONFIG['DLEXT']}"
  RBX_EXT = "lib/looksee/rbx.#{Config::CONFIG['DLEXT']}"
  JRUBY_EXT = 'lib/looksee/looksee.jar'

  case RUBY_ENGINE
  when 'jruby'
    task :build => JRUBY_EXT
    task :build_for_gem => :build
  when 'rbx'
    task :build => RBX_EXT
    task :build_for_gem
  else
    task :build => MRI_EXT
    task :build_for_gem
  end

  CLOBBER.include(MRI_EXT, JRUBY_EXT)
end

namespace :mri do
  file MRI_EXT do
    Dir.chdir 'ext/mri' do
      ruby 'extconf.rb'
      sh(RUBY_PLATFORM =~ /win32/ ? 'nmake' : 'make')
      sh "cp #{File.basename(MRI_EXT)} ../../#{MRI_EXT}"
    end
  end
end

namespace :rbx do
  file RBX_EXT do
    Dir.chdir 'ext/rbx' do
      ruby 'extconf.rb'
      sh(RUBY_PLATFORM =~ /win32/ ? 'nmake' : 'make')
      sh "cp #{File.basename(RBX_EXT)} ../../#{RBX_EXT}"
    end
  end
end

namespace :jruby do
  file JRUBY_EXT do
    class_path = "#{Config::CONFIG['prefix']}/lib/jruby.jar"
    sh "javac -g -classpath #{class_path} ext/jruby/looksee/*.java"
    cd 'ext/jruby' do
      sh "jar cf ../../#{JRUBY_EXT} looksee/*.class"
    end
  end
end
