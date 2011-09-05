ruby_engine = Object.const_defined?(:RUBY_ENGINE) ? RUBY_ENGINE : 'ruby'
extension = ruby_engine == 'ruby' ? 'mri' : ruby_engine

require 'mkmf'
$CPPFLAGS << " -DRUBY_VERSION=#{RUBY_VERSION.tr('.', '')}"
if extension == 'mri'
  if RUBY_VERSION >= '1.9.3'
    $CPPFLAGS << " -Imri/1.9.3"
  elsif RUBY_VERSION >= '1.9.2'
    $CPPFLAGS << " -Imri/1.9.2"
  end
end
create_makefile "looksee/#{extension}", extension
