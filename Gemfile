source :rubygems
gemspec

group :dev do
  case (RUBY_ENGINE rescue nil)
  when 'jruby'
    gem 'ruby-debug'
  when 'rbx'
    # Debugger is built-in.
  else
    if RUBY_VERSION >= '1.9'
      gem 'debugger', :require => 'ruby-debug'
    else
      gem 'ruby-debug'
    end
  end
end
