require 'mkmf'

$CPPFLAGS << " -DRUBY_VERSION=#{RUBY_VERSION.tr('.', '')}"
dir_config("looksee")

create_makefile("looksee")
