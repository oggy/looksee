# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{looksee}
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["George Ogata"]
  s.date = %q{2009-08-20}
  s.description = %q{Looksee lets you examine the method lookup path of objects in ways not
possible in plain ruby.}
  s.email = ["george.ogata@gmail.com"]
  s.extensions = ["ext/looksee/extconf.rb"]
  s.extra_rdoc_files = ["History.txt", "Manifest.txt"]
  s.files = [".autotest", "History.txt", "Manifest.txt", "README.rdoc", "Rakefile", "ext/looksee/extconf.rb", "ext/looksee/looksee.c", "ext/looksee/node-1.9.h", "lib/looksee.rb", "lib/looksee/shortcuts.rb", "lib/looksee/version.rb", "lib/looksee/wirble_compatibility.rb", "looksee.gemspec", "script/console", "script/destroy", "script/generate", "spec/looksee_spec.rb", "spec/spec_helper.rb", "spec/wirble_compatibility_spec.rb", "tasks/extconf.rake", "tasks/extconf/looksee.rake"]
  s.homepage = %q{http://github.com/oggy/looksee}
  s.rdoc_options = ["--main", "README.rdoc"]
  s.require_paths = ["lib", "ext/looksee"]
  s.rubyforge_project = %q{looksee}
  s.rubygems_version = %q{1.3.4}
  s.summary = %q{Looksee lets you examine the method lookup path of objects in ways not possible in plain ruby.}

  if s.respond_to? :specification_version then
    current_version = Gem::Specification::CURRENT_SPECIFICATION_VERSION
    s.specification_version = 3

    if Gem::Version.new(Gem::RubyGemsVersion) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<newgem>, [">= 1.5.2"])
      s.add_development_dependency(%q<rspec>, [">= 1.2.7"])
      s.add_development_dependency(%q<mocha>, [">= 0.9.5"])
      s.add_development_dependency(%q<hoe>, [">= 2.3.2"])
    else
      s.add_dependency(%q<newgem>, [">= 1.5.2"])
      s.add_dependency(%q<rspec>, [">= 1.2.7"])
      s.add_dependency(%q<mocha>, [">= 0.9.5"])
      s.add_dependency(%q<hoe>, [">= 2.3.2"])
    end
  else
    s.add_dependency(%q<newgem>, [">= 1.5.2"])
    s.add_dependency(%q<rspec>, [">= 1.2.7"])
    s.add_dependency(%q<mocha>, [">= 0.9.5"])
    s.add_dependency(%q<hoe>, [">= 2.3.2"])
  end
end
