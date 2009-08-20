#include "ruby.h"

#if RUBY_VERSION >= 190
#  include "node-1.9.h"
#  include "ruby/st.h"
#else
#  include "node.h"
#  include "st.h"
#endif

#if RUBY_VERSION < 187
#  define RCLASS_IV_TBL(c) (RCLASS(c)->iv_tbl)
#  define RCLASS_M_TBL(c) (RCLASS(c)->m_tbl)
#  define RCLASS_SUPER(c) (RCLASS(c)->super)
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

typedef struct add_method_if_matching_arg {
  VALUE names;
  int visibility;
} add_method_if_matching_arg_t;

#if RUBY_VERSION < 190
#  define VISIBILITY(node) ((node)->nd_noex & NOEX_MASK)
#else
#  define VISIBILITY(node) ((node)->nd_body->nd_noex & NOEX_MASK)
#endif

static int add_method_if_matching(ID method_name, NODE *body, add_method_if_matching_arg_t *arg) {
  /* This entry is for the internal allocator function. */
  if (method_name == ID_ALLOCATOR)
    return ST_CONTINUE;

  /* Module#undef_method sets body->nd_body to NULL. */
  if (!body || !body->nd_body)
    return ST_CONTINUE;

  if (VISIBILITY(body) == arg->visibility)
    rb_ary_push(arg->names, ID2SYM(method_name));
  return ST_CONTINUE;
}

static VALUE internal_instance_methods(VALUE klass, long visibility) {
  add_method_if_matching_arg_t arg;
  arg.names = rb_ary_new();
  arg.visibility = visibility;
  st_foreach(RCLASS_M_TBL(klass), add_method_if_matching, (st_data_t)&arg);
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

static int add_method_if_undefined(ID method_name, NODE *body, VALUE *names) {
  /* Module#undef_method sets body->nd_body to NULL. */
  if (body && !body->nd_body)
    rb_ary_push(*names, ID2SYM(method_name));
  return ST_CONTINUE;
}

/*
 * Return the list of undefined instance methods (as Symbols) of the
 * given internal class.
 */
VALUE Looksee_internal_undefined_instance_methods(VALUE self, VALUE klass) {
  VALUE names = rb_ary_new();
  st_foreach(RCLASS_M_TBL(klass), add_method_if_undefined, (st_data_t)&names);
  return names;
}

void Init_looksee(void) {
  VALUE mLooksee = rb_define_module("Looksee");
  rb_define_singleton_method(mLooksee, "internal_superclass", Looksee_internal_superclass, 1);
  rb_define_singleton_method(mLooksee, "internal_class", Looksee_internal_class, 1);
  rb_define_singleton_method(mLooksee, "internal_class_to_module", Looksee_internal_class_to_module, 1);
  rb_define_singleton_method(mLooksee, "internal_public_instance_methods", Looksee_internal_public_instance_methods, 1);
  rb_define_singleton_method(mLooksee, "internal_protected_instance_methods", Looksee_internal_protected_instance_methods, 1);
  rb_define_singleton_method(mLooksee, "internal_private_instance_methods", Looksee_internal_private_instance_methods, 1);
  rb_define_singleton_method(mLooksee, "internal_undefined_instance_methods", Looksee_internal_undefined_instance_methods, 1);
}
