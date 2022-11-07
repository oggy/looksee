require 'ritual'

ruby_engine = (Object.const_defined?(:RUBY_ENGINE) ? RUBY_ENGINE : 'ruby')
if ruby_engine == 'jruby'
  extension :type => :jruby, :path => 'ext/jruby', :install_as => "lib/looksee/JRuby"
else
  name = ruby_engine == 'ruby' ? 'mri' : ruby_engine
  extension :build_as => "ext/#{name}", :install_as => "lib/looksee/#{name}"
end

task :default => [:clobber, :ext] do
  sh 'bundle exec rspec -I. spec'
end

task :test_all do
  docker_configs.each do |config|
    docker_run(config, 'rspec')
  end
end

task :console, :config do |task, args|
  docker_run(args[:config], nil)
end

task :test, :config do |task, args|
  docker_run(args[:config], 'rspec')
end

task :shell, :config do |task, args|
  docker_run(args[:config], '/bin/bash')
end

def docker_configs
  Dir['Dockerfile.*'].map { |path| path[/(?<=\.).*?\z/] }
end

def docker_run(config, command)
  sh "docker build -f Dockerfile.#{config} -t looksee:#{config} ."
  sh "docker run -it looksee:#{config} #{command}"
end
