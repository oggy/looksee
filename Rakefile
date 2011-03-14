require 'ritual'

ruby_engine = (Object.const_defined?(:RUBY_ENGINE) ? RUBY_ENGINE : 'ruby')
if ruby_engine == 'jruby'
  extension :jruby, :type => :jruby
else
  name = ruby_engine == 'ruby' ? 'mri' : ruby_engine
  extension :build_as => "ext/#{name}", :install_as => "lib/looksee/#{name}"
end
