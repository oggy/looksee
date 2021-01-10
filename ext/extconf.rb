ruby_engine = Object.const_defined?(:RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'
extension = ruby_engine == 'ruby' ? 'mri' : ruby_engine

require 'mkmf'
$CPPFLAGS << " -DRUBY_VERSION=#{RUBY_VERSION.tr('.', '')}"
if extension == 'mri'
  if RUBY_VERSION >= '3.0.0'
    $CPPFLAGS << " -Imri/3.0.0"
  elsif RUBY_VERSION >= '2.7.0'
    $CPPFLAGS << " -Imri/2.7.0"
  elsif RUBY_VERSION >= '2.3.0'
    $CPPFLAGS << " -Imri/2.3.0"
  elsif RUBY_VERSION >= '2.2.0'
    $CPPFLAGS << " -Imri/2.2.0"
  elsif RUBY_VERSION >= '2.1.0'
    $CPPFLAGS << " -Imri/2.1.0"
  end
end
create_makefile "looksee/#{extension}", extension
