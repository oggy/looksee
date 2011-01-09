require 'mkmf'

$CPPFLAGS << " -DRUBY_VERSION=#{RUBY_VERSION.tr('.', '')}"

create_makefile("mri")
