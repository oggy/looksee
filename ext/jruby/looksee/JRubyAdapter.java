package looksee;

import java.lang.reflect.Field;
import java.util.Map;
import org.jruby.MetaClass;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyMethod;
import org.jruby.RubyModule;
import org.jruby.RubyObject;
import org.jruby.RubyProc;
import org.jruby.RubyString;
import org.jruby.RubyUnboundMethod;
import org.jruby.IncludedModuleWrapper;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.internal.runtime.methods.AliasMethod;
import org.jruby.internal.runtime.methods.DynamicMethod;
import org.jruby.internal.runtime.methods.MethodMethod;
import org.jruby.internal.runtime.methods.ProcMethod;
import org.jruby.internal.runtime.methods.WrapperMethod;
import org.jruby.lexer.yacc.ISourcePosition;
import org.jruby.runtime.PositionAware;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.Visibility;
import org.jruby.runtime.builtin.IRubyObject;

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

  @JRubyMethod(name = "included_class?")
  public static IRubyObject isIncludedClass(ThreadContext context, IRubyObject self, IRubyObject object) {
    Ruby runtime = context.getRuntime();
    return runtime.newBoolean(object instanceof IncludedModuleWrapper);
  }

  @JRubyMethod(name = "singleton_class?")
  public static IRubyObject isSingletonClass(ThreadContext context, IRubyObject self, IRubyObject object) {
    Ruby runtime = context.getRuntime();
    return runtime.newBoolean(object instanceof MetaClass);
  }

  @JRubyMethod(name = "singleton_instance")
  public static IRubyObject singletonInstance(ThreadContext context, IRubyObject self, IRubyObject singleton_class) {
    Ruby runtime = context.getRuntime();
    if (singleton_class instanceof MetaClass)
      return ((MetaClass)singleton_class).getAttached();
    else
      throw runtime.newTypeError("expected singleton class, got " + singleton_class.getMetaClass().getName());
  }

  @JRubyMethod(name = "module_name")
  public static IRubyObject moduleName(ThreadContext context, IRubyObject self, IRubyObject module) {
    Ruby runtime = context.getRuntime();
    if (module instanceof IncludedModuleWrapper)
      return runtime.newString(((IncludedModuleWrapper)module).getNonIncludedClass().getName() + " (included)");
    if (module instanceof RubyModule)
      return ((RubyModule)module).name();
    else
      throw runtime.newTypeError("expected Module, got " + module.getMetaClass().getName());
  }

  @JRubyMethod(name = "source_location")
  public static IRubyObject sourceLocation(ThreadContext context, IRubyObject self, IRubyObject arg) {
    Ruby runtime = context.getRuntime();
    if (!(arg instanceof RubyUnboundMethod))
      throw runtime.newTypeError("expected UnboundMethod, got " + arg.getMetaClass().getName());

    IRubyObject sourceLocation = ((RubyUnboundMethod)arg).source_location(context);
    if (!sourceLocation.isNil())
      return sourceLocation;

    // source_location doesn't always work. If it returns nil, try a little harder.
    DynamicMethod method = (DynamicMethod)getPrivateField(runtime, RubyMethod.class, "method", arg);
    return methodSourceLocation(runtime, method);
  }

  public static IRubyObject methodSourceLocation(Ruby runtime, DynamicMethod method) {
    if (method instanceof PositionAware) {
      PositionAware positionAware = (PositionAware)method;
      return runtime.newArray(runtime.newString(positionAware.getFile()),
                              runtime.newFixnum(positionAware.getLine() + 1));
    } else if (method instanceof ProcMethod) {
      RubyProc proc = (RubyProc)getPrivateField(runtime, ProcMethod.class, "proc", method);
      String file = (String)getPrivateField(runtime, RubyProc.class, "file", proc);
      int line = getPrivateIntField(runtime, RubyProc.class, "line", proc);
      RubyString rubyFile = runtime.newString(file);
      RubyFixnum rubyLine = runtime.newFixnum(line + 1);
      return runtime.newArray(rubyFile, rubyLine);
    } else if (method instanceof AliasMethod) {
      method = method.getRealMethod();
      return methodSourceLocation(runtime, method);
    } else if (method instanceof MethodMethod) {
      // MethodMethod.getRealMethod and RubyMethod.getMethod are JRuby >= 1.6 only.
      RubyUnboundMethod unboundMethod = (RubyUnboundMethod)getPrivateField(runtime, MethodMethod.class, "method", method);
      DynamicMethod realMethod = (DynamicMethod)getPrivateField(runtime, RubyMethod.class, "method", unboundMethod);
      return methodSourceLocation(runtime, realMethod);
    } else if (method instanceof WrapperMethod) {
      method = (DynamicMethod)getPrivateField(runtime, WrapperMethod.class, "method", method);
      return methodSourceLocation(runtime, method);
    }
    return runtime.getNil();
  }

  // Yes, we are evil.
  private static Object getPrivateField(Ruby runtime, Class klass, String name, Object receiver) {
    try {
      Field field = klass.getDeclaredField(name);
      field.setAccessible(true);
      return field.get(receiver);
    } catch (IllegalAccessException e) {
      throw runtime.newTypeError("[LOOKSEE BUG] unexpected exception: " + e.getClass().getName() + ": " + e.getMessage() + " (klass = " + klass.getName() + ")");
    } catch (NoSuchFieldException e) {
      throw runtime.newTypeError("[LOOKSEE BUG] unexpected exception: " + e.getClass().getName() + ": " + e.getMessage() + " (klass = " + klass.getName() + ")");
    }
  }

  private static int getPrivateIntField(Ruby runtime, Class klass, String name, Object receiver) {
    try {
      Field field = klass.getDeclaredField(name);
      field.setAccessible(true);
      return field.getInt(receiver);
    } catch (IllegalAccessException e) {
      throw runtime.newTypeError("[LOOKSEE BUG] unexpected exception: " + e.getClass().getName() + ": " + e.getMessage() + " (klass = " + klass.getName() + ")");
    } catch (NoSuchFieldException e) {
      throw runtime.newTypeError("[LOOKSEE BUG] unexpected exception: " + e.getClass().getName() + ": " + e.getMessage() + " (klass = " + klass.getName() + ")");
    }
  }
}
