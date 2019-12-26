#include "ruby.h"

#if RUBY_VERSION >= 230
#  define VM_ASSERT(expr) ((void)0)
#endif

#include "method.h"
#include "internal.h"

#ifndef Looksee_method_table_foreach
#  define Looksee_method_table_foreach st_foreach
#  define Looksee_method_table_lookup st_lookup
#endif

#if RUBY_VERSION < 230
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
#endif

/*
 * Return the list of undefined instance methods (as Symbols) of the
 * given internal class.
 */
VALUE Looksee_internal_undefined_instance_methods(VALUE self, VALUE klass) {
#if RUBY_VERSION >= 230
  static int warned = 0;
  if (!warned) {
    rb_warn("Looksee cannot display undef-ed methods on MRI 2.3 or later");
    warned = 1;
  }
  return rb_ary_new();
#else
  VALUE names = rb_ary_new();
  if (RCLASS_ORIGIN(klass) != klass)
    klass = RCLASS_ORIGIN(klass);
  Looksee_method_table_foreach(RCLASS_M_TBL(klass), add_method_if_undefined, (st_data_t)&names);
  return names;
#endif
}

VALUE Looksee_singleton_instance(VALUE self, VALUE klass) {
  if (!SPECIAL_CONST_P(klass) && BUILTIN_TYPE(klass) == T_CLASS && FL_TEST(klass, FL_SINGLETON)) {
    VALUE object;
    if (!Looksee_method_table_lookup(RCLASS_IV_TBL(klass), rb_intern("__attached__"), (st_data_t *)&object))
      rb_raise(rb_eRuntimeError, "[looksee bug] can't find singleton object");
    return object;
  } else {
    return Qnil;
  }
}

void Init_mri(void) {
  VALUE mLooksee = rb_const_get(rb_cObject, rb_intern("Looksee"));
  VALUE mAdapter = rb_const_get(mLooksee, rb_intern("Adapter"));
  VALUE mBase = rb_const_get(mAdapter, rb_intern("Base"));
  VALUE mMRI = rb_define_class_under(mAdapter, "MRI", mBase);
  rb_define_method(mMRI, "internal_undefined_instance_methods", Looksee_internal_undefined_instance_methods, 1);
  rb_define_method(mMRI, "singleton_instance", Looksee_singleton_instance, 1);
}
