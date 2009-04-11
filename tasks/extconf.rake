namespace :extconf do
  desc "Compiles the Ruby extension"
  task :compile
end

task :compile => "extconf:compile"

task :test => :compile

BIN = "*.{bundle,jar,so,obj,pdb,lib,def,exp}"
$hoe.clean_globs |= ["ext/**/#{BIN}", "lib/**/#{BIN}", 'ext/**/Makefile']
$hoe.spec.require_paths = Dir['{lib,ext/*}']
$hoe.spec.extensions = FileList["ext/**/extconf.rb"].to_a
