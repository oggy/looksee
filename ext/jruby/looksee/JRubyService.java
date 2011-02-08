package looksee;

import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.RubyModule;
import org.jruby.RubyClass;
import org.jruby.runtime.load.BasicLibraryService;

public class JRubyService implements BasicLibraryService {
  public boolean basicLoad(Ruby runtime) {
    RubyModule mAdapter = (RubyModule)runtime.getClassFromPath("Looksee::Adapter");
    RubyClass cBase = (RubyClass)runtime.getClassFromPath("Looksee::Adapter::Base");
    RubyClass cJRuby = runtime.defineClassUnder("JRuby", cBase, cBase.getAllocator(), mAdapter);
    cJRuby.defineAnnotatedMethods(JRubyAdapter.class);
    return true;
  }
}
