#include "ruby.h"

#if RUBY_VERSION >= 192
#  include "vm_core.h"
#  include "method.h"
#  include "ruby/st.h"
#elif RUBY_VERSION >= 190
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

#if RUBY_VERSION >= 192

#  define VISIBILITY_TYPE rb_method_flag_t

typedef struct add_method_if_matching_arg {
  VALUE names;
  VISIBILITY_TYPE visibility;
} add_method_if_matching_arg_t;

static int add_method_if_matching(ID method_name, rb_method_entry_t *me, add_method_if_matching_arg_t *arg) {
  if (method_name == ID_ALLOCATOR)
    return ST_CONTINUE;

  if (UNDEFINED_METHOD_ENTRY_P(me))
    return ST_CONTINUE;

  if ((me->flag & NOEX_MASK) == arg->visibility)
    rb_ary_push(arg->names, ID2SYM(method_name));

  return ST_CONTINUE;
}

static int add_method_if_undefined(ID method_name, rb_method_entry_t *me, VALUE *names) {
  if (UNDEFINED_METHOD_ENTRY_P(me))
    rb_ary_push(*names, ID2SYM(method_name));
  return ST_CONTINUE;
}

#else

#  if RUBY_VERSION >= 190
#    define VISIBILITY(node) ((node)->nd_body->nd_noex & NOEX_MASK)
#  else
#    define VISIBILITY(node) ((node)->nd_noex & NOEX_MASK)
#  endif

#  define VISIBILITY_TYPE unsigned long

typedef struct add_method_if_matching_arg {
  VALUE names;
  VISIBILITY_TYPE visibility;
} add_method_if_matching_arg_t;

static int add_method_if_matching(ID method_name, NODE *body, add_method_if_matching_arg_t *arg) {
  /* This entry is for the internal allocator function. */
  if (method_name == ID_ALLOCATOR)
    return ST_CONTINUE;

  /* Module#undef_method:
   *   * sets body->nd_body to NULL in ruby <= 1.8
   *   * sets body to NULL in ruby >= 1.9
   */
  if (!body || !body->nd_body)
    return ST_CONTINUE;

  if (VISIBILITY(body) == arg->visibility)
    rb_ary_push(arg->names, ID2SYM(method_name));
  return ST_CONTINUE;
}

static int add_method_if_undefined(ID method_name, NODE *body, VALUE *names) {
  if (!body || !body->nd_body)
    rb_ary_push(*names, ID2SYM(method_name));
  return ST_CONTINUE;
}

#endif

static VALUE internal_instance_methods(VALUE klass, VISIBILITY_TYPE visibility) {
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

/*
 * Return the list of undefined instance methods (as Symbols) of the
 * given internal class.
 */
VALUE Looksee_internal_undefined_instance_methods(VALUE self, VALUE klass) {
  VALUE names = rb_ary_new();
  st_foreach(RCLASS_M_TBL(klass), add_method_if_undefined, (st_data_t)&names);
  return names;
}

VALUE Looksee_singleton_class_p(VALUE self, VALUE object) {
  return BUILTIN_TYPE(object) == T_CLASS && FL_TEST(object, FL_SINGLETON) ? Qtrue : Qfalse;
}

VALUE Looksee_singleton_instance(VALUE self, VALUE singleton_class) {
  if (BUILTIN_TYPE(singleton_class) == T_CLASS && FL_TEST(singleton_class, FL_SINGLETON)) {
    VALUE object;
    if (!st_lookup(RCLASS_IV_TBL(singleton_class), rb_intern("__attached__"), (st_data_t *)&object))
      rb_raise(rb_eRuntimeError, "[looksee bug] can't find singleton object");
    return object;
  } else {
    rb_raise(rb_eTypeError, "expected singleton class, got %s", rb_obj_classname(singleton_class));
  }
}

VALUE Looksee_module_name(VALUE self, VALUE module) {
  if (BUILTIN_TYPE(module) == T_CLASS || BUILTIN_TYPE(module) == T_MODULE) {
    VALUE name = rb_mod_name(module);
    return name == Qnil ? rb_str_new2("") : name;
  } else {
    rb_raise(rb_eTypeError, "expected module, got %s", rb_obj_classname(module));
  }
}

#if RUBY_VERSION < 190

#include "env-1.8.h"
#include "eval_c-1.8.h"

/*
 * Return the source file and line number of the given object and method.
 */
VALUE Looksee_source_location(VALUE self, VALUE unbound_method) {
  if (!rb_obj_is_kind_of(unbound_method, rb_cUnboundMethod))
    rb_raise(rb_eTypeError, "expected UnboundMethod, got %s", rb_obj_classname(unbound_method));

  struct METHOD *method;
  Data_Get_Struct(unbound_method, struct METHOD, method);

  NODE *node;
  switch (nd_type(method->body)) {
    // Can't be a FBODY or ZSUPER.
  case NODE_SCOPE:
    node = method->body->nd_defn;
    break;
  case NODE_BMETHOD:
    {
      struct BLOCK *block;
      Data_Get_Struct(method->body->nd_orig, struct BLOCK, block);
      (node = block->frame.node) || (node = block->body);
      // Proc#to_s suggests this may be NULL sometimes.
      if (!node)
        return Qnil;
    }
    break;
  case NODE_DMETHOD:
    {
      struct METHOD *original_method;
      NODE *body = method->body;
      Data_Get_Struct(body->nd_orig, struct METHOD, original_method);
      node = original_method->body->nd_defn;
    }
    break;
  default:
    return Qnil;
  }
  VALUE file = rb_str_new2(node->nd_file);
  VALUE line = INT2NUM(nd_line(node));
  VALUE location = rb_ary_new2(2);
  rb_ary_store(location, 0, file);
  rb_ary_store(location, 1, line);
  return location;
}

#endif

void Init_mri(void) {
  VALUE mLooksee = rb_const_get(rb_cObject, rb_intern("Looksee"));
  VALUE mAdapter = rb_const_get(mLooksee, rb_intern("Adapter"));
  VALUE mBase = rb_const_get(mAdapter, rb_intern("Base"));
  VALUE mMRI = rb_define_class_under(mAdapter, "MRI", mBase);
  rb_define_method(mMRI, "internal_superclass", Looksee_internal_superclass, 1);
  rb_define_method(mMRI, "internal_class", Looksee_internal_class, 1);
  rb_define_method(mMRI, "internal_class_to_module", Looksee_internal_class_to_module, 1);
  rb_define_method(mMRI, "internal_public_instance_methods", Looksee_internal_public_instance_methods, 1);
  rb_define_method(mMRI, "internal_protected_instance_methods", Looksee_internal_protected_instance_methods, 1);
  rb_define_method(mMRI, "internal_private_instance_methods", Looksee_internal_private_instance_methods, 1);
  rb_define_method(mMRI, "internal_undefined_instance_methods", Looksee_internal_undefined_instance_methods, 1);
  rb_define_method(mMRI, "singleton_class?", Looksee_singleton_class_p, 1);
  rb_define_method(mMRI, "singleton_instance", Looksee_singleton_instance, 1);
  rb_define_method(mMRI, "module_name", Looksee_module_name, 1);
#if RUBY_VERSION < 190
  rb_define_method(mMRI, "source_location", Looksee_source_location, 1);
#endif
}
