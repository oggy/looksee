require 'ritual'

ruby_engine = (Object.const_defined?(:RUBY_ENGINE) ? RUBY_ENGINE : 'ruby')
if ruby_engine == 'jruby'
  extension :type => :jruby, :path => 'ext/jruby', :install_as => "lib/looksee/JRuby"
else
  name = ruby_engine == 'ruby' ? 'mri' : ruby_engine
  extension :build_as => "ext/#{name}", :install_as => "lib/looksee/#{name}"
end
