#include "ruby.h"

VALUE Looksee_internal_class(VALUE self, VALUE object) {
  return CLASS_OF(object);
}

void Init_rbx(void) {
  VALUE mLooksee = rb_const_get(rb_cObject, rb_intern("Looksee"));
  VALUE mAdapter = rb_const_get(mLooksee, rb_intern("Adapter"));
  VALUE mBase = rb_const_get(mAdapter, rb_intern("Base"));
  VALUE mRubinius = rb_define_class_under(mAdapter, "Rubinius", mBase);
  rb_define_method(mRubinius, "internal_class", Looksee_internal_class, 1);
}
