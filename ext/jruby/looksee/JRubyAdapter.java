package looksee;

import java.util.Map;
import org.jruby.MetaClass;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.internal.runtime.methods.DynamicMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

@JRubyClass(name = "Looksee::Adapter::JRuby")
public class JRubyAdapter extends RubyObject {
  public JRubyAdapter(Ruby runtime, RubyClass klass) {
    super(runtime, klass);
  }

  @JRubyMethod(name = "internal_undefined_instance_methods")
  public static RubyArray internalUndefinedInstanceMethods(ThreadContext context, IRubyObject self, IRubyObject module) {
    Ruby runtime = context.getRuntime();
    RubyArray result = runtime.newArray();
    for (Map.Entry<String, DynamicMethod> entry : ((RubyModule)module).getMethods().entrySet()) {
      if (entry.getValue().isUndefined())
        result.add(runtime.newSymbol(entry.getKey()));
    }
    return result;
  }

  @JRubyMethod(name = "singleton_instance")
  public static IRubyObject singletonInstance(ThreadContext context, IRubyObject self, IRubyObject singleton_class) {
    Ruby runtime = context.getRuntime();
    if (singleton_class instanceof MetaClass)
      return ((MetaClass)singleton_class).getAttached();
    else
      return runtime.getNil();
  }
}
