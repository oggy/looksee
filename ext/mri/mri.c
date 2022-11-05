#include "ruby.h"

#if RUBY_VERSION < 320
/*
 * Return the list of undefined instance methods (as Symbols) of the
 * given internal class.
 */
VALUE Looksee_internal_undefined_instance_methods(VALUE self, VALUE klass) {
  static int warned = 0;
  if (!warned) {
    rb_warn("Looksee cannot display undef-ed methods on MRI < 3.2");
    warned = 1;
  }
  return rb_ary_new();
}
#endif

VALUE Looksee_singleton_instance(VALUE self, VALUE klass) {
  if (!SPECIAL_CONST_P(klass) && BUILTIN_TYPE(klass) == T_CLASS && FL_TEST(klass, FL_SINGLETON)) {
    VALUE object = rb_ivar_get(klass, rb_intern("__attached__"));
    if (object == Qnil)
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
#if RUBY_VERSION < 320
  rb_define_method(mMRI, "internal_undefined_instance_methods", Looksee_internal_undefined_instance_methods, 1);
#endif
  rb_define_method(mMRI, "singleton_instance", Looksee_singleton_instance, 1);
}
