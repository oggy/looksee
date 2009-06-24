#include "ruby.h"

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
  return RBASIC(object)->klass;
}

/*
 * Return the class or module that the given internal class
 * represents.
 *
 * If a class is given, this is the class.  If an iclass is given,
 * this is the module it represents in the lookup chain.
 */
VALUE Looksee_internal_class_to_module(VALUE self, VALUE internal_class) {
  if (!SPECIAL_CONST_P(internal_class)) {
    switch (BUILTIN_TYPE(internal_class)) {
    case T_ICLASS:
      return RBASIC(internal_class)->klass;
    case T_CLASS:
      return internal_class;
    }
  }
  rb_raise(rb_eArgError, "not an internal class: %s", RSTRING_PTR(rb_inspect(internal_class)));
}

void Init_looksee(void) {
  VALUE mLooksee = rb_define_module("Looksee");
  rb_define_singleton_method(mLooksee, "internal_superclass", Looksee_internal_superclass, 1);
  rb_define_singleton_method(mLooksee, "internal_class", Looksee_internal_class, 1);
  rb_define_singleton_method(mLooksee, "internal_class_to_module", Looksee_internal_class_to_module, 1);
}
