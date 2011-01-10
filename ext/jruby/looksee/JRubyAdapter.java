package looksee;

import java.util.Map;
import org.jruby.Ruby;
import org.jruby.RubyObject;
import org.jruby.RubyModule;
import org.jruby.RubyClass;
import org.jruby.RubyArray;
import org.jruby.IncludedModuleWrapper;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.internal.runtime.methods.DynamicMethod;

@JRubyClass(name = "Looksee::Adapter::JRuby")
public class JRubyAdapter extends RubyObject {
  public JRubyAdapter(Ruby runtime, RubyClass klass) {
    super(runtime, klass);
  }

  @JRubyMethod(name = "internal_superclass")
  public static IRubyObject internalSuperclass(ThreadContext context, IRubyObject self, IRubyObject internalClass) {
    return ((RubyModule)internalClass).getSuperClass();
  }

  @JRubyMethod(name = "internal_class")
  public static IRubyObject internalClass(ThreadContext context, IRubyObject self, IRubyObject object) {
    return object.getMetaClass();
  }

  @JRubyMethod(name = "internal_class_to_module")
  public static IRubyObject internalClassToModule(ThreadContext context, IRubyObject self, IRubyObject internalClass) {
    if (internalClass instanceof IncludedModuleWrapper)
      return ((IncludedModuleWrapper)internalClass).getNonIncludedClass();
    else
      return internalClass;
  }

  @JRubyMethod(name = "internal_public_instance_methods")
  public static IRubyObject internalPublicInstanceMethods(ThreadContext context, IRubyObject self, IRubyObject module) {
    return findMethodsByVisibility(context.getRuntime(), module, Visibility.PUBLIC);
  }

  @JRubyMethod(name = "internal_protected_instance_methods")
  public static IRubyObject internalProtectedInstanceMethods(ThreadContext context, IRubyObject self, IRubyObject module) {
    return findMethodsByVisibility(context.getRuntime(), module, Visibility.PROTECTED);
  }

  @JRubyMethod(name = "internal_private_instance_methods")
  public static IRubyObject internalPrivateInstanceMethods(ThreadContext context, IRubyObject self, IRubyObject module) {
    return findMethodsByVisibility(context.getRuntime(), module, Visibility.PRIVATE);
  }

  private static RubyArray findMethodsByVisibility(Ruby runtime, IRubyObject module, Visibility visibility) {
    RubyArray result = runtime.newArray();
    for (Map.Entry<String, DynamicMethod> entry : ((RubyModule)module).getMethods().entrySet()) {
      if (entry.getValue().getVisibility() == visibility)
        result.add(runtime.newSymbol(entry.getKey()));
    }
    return result;
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
}
