require 'ritual'

case (Object.const_defined?(:RUBY_ENGINE) ? RUBY_ENGINE : 'ruby')
when 'ruby'
  extension :mri
when 'rbx'
  extension :rbx
when 'jruby'
  extension :jruby, :type => :jruby
end
