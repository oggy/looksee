#include "ruby.h"

#include "method.h"
#include "internal.h"

#ifndef Looksee_method_table_foreach
#  define Looksee_method_table_foreach st_foreach
#  define Looksee_method_table_lookup st_lookup
#endif

static int add_method_if_undefined(ID method_name, rb_method_entry_t *me, VALUE *names) {
#ifdef ID_ALLOCATOR
  /* The allocator can be undefined with rb_undef_alloc_func, e.g. Struct. */
  if (method_name == ID_ALLOCATOR)
    return ST_CONTINUE;
#endif

  if (UNDEFINED_METHOD_ENTRY_P(me))
    rb_ary_push(*names, ID2SYM(method_name));
  return ST_CONTINUE;
}

/*
 * Return the list of undefined instance methods (as Symbols) of the
 * given internal class.
 */
VALUE Looksee_internal_undefined_instance_methods(VALUE self, VALUE klass) {
  VALUE names = rb_ary_new();
  if (RCLASS_ORIGIN(klass) != klass)
    klass = RCLASS_ORIGIN(klass);
  Looksee_method_table_foreach(RCLASS_M_TBL(klass), add_method_if_undefined, (st_data_t)&names);
  return names;
}

VALUE Looksee_singleton_instance(VALUE self, VALUE klass) {
  if (!IMMEDIATE_P(klass) && BUILTIN_TYPE(klass) == T_CLASS && FL_TEST(klass, FL_SINGLETON)) {
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
