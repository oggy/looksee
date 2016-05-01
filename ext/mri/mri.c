#include "ruby.h"

#if RUBY_VERSION >= 200
#  include "method.h"
#  include "internal.h"
#elif RUBY_VERSION >= 193
#  include "ruby/st.h"
#  ifdef SA_EMPTY
#    include "internal_falcon.h"
#    define Looksee_method_table_foreach sa_foreach
#    define Looksee_method_table_lookup sa_lookup
#  else
#    include "internal.h"
#  endif
#  include "vm_core.h"
#  include "method.h"
#endif

#ifndef Looksee_method_table_foreach
#  define Looksee_method_table_foreach st_foreach
#  define Looksee_method_table_lookup st_lookup
#endif

/*
 * Return the internal superclass of this class.
 *
 * This is either a Class or "IClass."  IClasses represent Modules
 * included in the ancestry, and should be treated as opaque objects
 * in ruby space. Convert the IClass to a Module using #iclass_to_module
 * before using it in ruby.
 */
VALUE Looksee_internal_superclass(VALUE self, VALUE internal_class) {
  VALUE super = RCLASS_SUPER(internal_class);
  if (!super)
    return Qnil;
  return super;
}

/*
 * Return the internal class of the given object.
 *
 * This is either the object's singleton class, if it exists, or the
 * object's birth class.
 */
VALUE Looksee_internal_class(VALUE self, VALUE object) {
  return CLASS_OF(object);
}

#  define VISIBILITY_TYPE rb_method_flag_t

typedef struct add_method_if_matching_arg {
  VALUE names;
  VISIBILITY_TYPE visibility;
} add_method_if_matching_arg_t;

static int add_method_if_matching(ID method_name, rb_method_entry_t *me, add_method_if_matching_arg_t *arg) {
#  ifdef ID_ALLOCATOR
  if (method_name == ID_ALLOCATOR)
    return ST_CONTINUE;
#  endif

  if (UNDEFINED_METHOD_ENTRY_P(me))
    return ST_CONTINUE;

  if ((me->flag & NOEX_MASK) == arg->visibility)
    rb_ary_push(arg->names, ID2SYM(method_name));

  return ST_CONTINUE;
}

static int add_method_if_undefined(ID method_name, rb_method_entry_t *me, VALUE *names) {
#  ifdef ID_ALLOCATOR
  /* The allocator can be undefined with rb_undef_alloc_func, e.g. Struct. */
  if (method_name == ID_ALLOCATOR)
    return ST_CONTINUE;
#  endif

  if (UNDEFINED_METHOD_ENTRY_P(me))
    rb_ary_push(*names, ID2SYM(method_name));
  return ST_CONTINUE;
}

static VALUE internal_instance_methods(VALUE klass, VISIBILITY_TYPE visibility) {
  add_method_if_matching_arg_t arg;
  arg.names = rb_ary_new();
  arg.visibility = visibility;

  Looksee_method_table_foreach(RCLASS_M_TBL(klass), add_method_if_matching, (st_data_t)&arg);
  return arg.names;
}

/*
 * Return the list of public instance methods (as Symbols) of the
 * given internal class.
 */
VALUE Looksee_internal_public_instance_methods(VALUE self, VALUE klass) {
  return internal_instance_methods(klass, NOEX_PUBLIC);
}

/*
 * Return the list of protected instance methods (as Symbols) of the
 * given internal class.
 */
VALUE Looksee_internal_protected_instance_methods(VALUE self, VALUE klass) {
  return internal_instance_methods(klass, NOEX_PROTECTED);
}

/*
 * Return the list of private instance methods (as Symbols) of the
 * given internal class.
 */
VALUE Looksee_internal_private_instance_methods(VALUE self, VALUE klass) {
  return internal_instance_methods(klass, NOEX_PRIVATE);
}

/*
 * Return the list of undefined instance methods (as Symbols) of the
 * given internal class.
 */
VALUE Looksee_internal_undefined_instance_methods(VALUE self, VALUE klass) {
  VALUE names = rb_ary_new();
  Looksee_method_table_foreach(RCLASS_M_TBL(klass), add_method_if_undefined, (st_data_t)&names);
  return names;
}

/*
 * Return true if the given object is an included class or origin class, false
 * otherwise.
 */
VALUE Looksee_included_class_p(VALUE self, VALUE object) {
  return !SPECIAL_CONST_P(object) && BUILTIN_TYPE(object) == T_ICLASS ?
    Qtrue : Qfalse;
}

VALUE Looksee_singleton_class_p(VALUE self, VALUE object) {
  return BUILTIN_TYPE(object) == T_CLASS && FL_TEST(object, FL_SINGLETON) ? Qtrue : Qfalse;
}

VALUE Looksee_singleton_instance(VALUE self, VALUE singleton_class) {
  if (BUILTIN_TYPE(singleton_class) == T_CLASS && FL_TEST(singleton_class, FL_SINGLETON)) {
    VALUE object;
    if (!Looksee_method_table_lookup(RCLASS_IV_TBL(singleton_class), rb_intern("__attached__"), (st_data_t *)&object))
      rb_raise(rb_eRuntimeError, "[looksee bug] can't find singleton object");
    return object;
  } else {
    rb_raise(rb_eTypeError, "expected singleton class, got %s", rb_obj_classname(singleton_class));
  }
}

VALUE Looksee_real_module(VALUE self, VALUE module_or_included_class) {
  if (BUILTIN_TYPE(module_or_included_class) == T_ICLASS)
    return RBASIC(module_or_included_class)->klass;
  else
    return module_or_included_class;
}

VALUE Looksee_module_name(VALUE self, VALUE module) {
  if (BUILTIN_TYPE(module) == T_CLASS || BUILTIN_TYPE(module) == T_MODULE) {
    VALUE name = rb_mod_name(module);
    return name == Qnil ? rb_str_new2("") : name;
  } else if (BUILTIN_TYPE(module) == T_ICLASS) {
    VALUE wrapped = RBASIC(module)->klass;
    VALUE name = Looksee_module_name(self, wrapped);
    if (BUILTIN_TYPE(wrapped) == T_CLASS)
      name = rb_str_cat2(name, " (origin)");
    return name;
  } else {
    rb_raise(rb_eTypeError, "expected module, got %s", rb_obj_classname(module));
  }
}

void Init_mri(void) {
  VALUE mLooksee = rb_const_get(rb_cObject, rb_intern("Looksee"));
  VALUE mAdapter = rb_const_get(mLooksee, rb_intern("Adapter"));
  VALUE mBase = rb_const_get(mAdapter, rb_intern("Base"));
  VALUE mMRI = rb_define_class_under(mAdapter, "MRI", mBase);
  rb_define_method(mMRI, "internal_superclass", Looksee_internal_superclass, 1);
  rb_define_method(mMRI, "internal_class", Looksee_internal_class, 1);
  rb_define_method(mMRI, "internal_public_instance_methods", Looksee_internal_public_instance_methods, 1);
  rb_define_method(mMRI, "internal_protected_instance_methods", Looksee_internal_protected_instance_methods, 1);
  rb_define_method(mMRI, "internal_private_instance_methods", Looksee_internal_private_instance_methods, 1);
  rb_define_method(mMRI, "internal_undefined_instance_methods", Looksee_internal_undefined_instance_methods, 1);
  rb_define_method(mMRI, "included_class?", Looksee_included_class_p, 1);
  rb_define_method(mMRI, "singleton_class?", Looksee_singleton_class_p, 1);
  rb_define_method(mMRI, "singleton_instance", Looksee_singleton_instance, 1);
  rb_define_method(mMRI, "real_module", Looksee_real_module, 1);
  rb_define_method(mMRI, "module_name", Looksee_module_name, 1);
}
