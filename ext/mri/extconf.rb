require 'mkmf'
$CPPFLAGS << " -DRUBY_VERSION=#{RUBY_VERSION.tr('.', '')}"
$CPPFLAGS << " -I1.9.2" if RUBY_VERSION >= '1.9.2'
create_makefile 'looksee/mri'
