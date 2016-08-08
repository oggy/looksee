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
#elif RUBY_VERSION >= 192
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

#ifndef Looksee_method_table_foreach
#  define Looksee_method_table_foreach st_foreach
#  define Looksee_method_table_lookup st_lookup
#endif

#if RUBY_VERSION < 187
#  define RCLASS_IV_TBL(c) (RCLASS(c)->iv_tbl)
#  define RCLASS_M_TBL(c) (RCLASS(c)->m_tbl)
#  define RCLASS_SUPER(c) (RCLASS(c)->super)
#endif

#if RUBY_VERSION >= 192

#  define VISIBILITY_TYPE rb_method_flag_t

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

#else

#  if RUBY_VERSION >= 190
#    define VISIBILITY(node) ((node)->nd_body->nd_noex & NOEX_MASK)
#  else
#    define VISIBILITY(node) ((node)->nd_noex & NOEX_MASK)
#  endif

#  define VISIBILITY_TYPE unsigned long

static int add_method_if_undefined(ID method_name, NODE *body, VALUE *names) {
#  ifdef ID_ALLOCATOR
  /* The allocator can be undefined with rb_undef_alloc_func, e.g. Struct. */
  if (method_name == ID_ALLOCATOR)
    return ST_CONTINUE;
#  endif

  if (!body || !body->nd_body)
    rb_ary_push(*names, ID2SYM(method_name));
  return ST_CONTINUE;
}

#endif

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
  rb_define_method(mMRI, "internal_undefined_instance_methods", Looksee_internal_undefined_instance_methods, 1);
  rb_define_method(mMRI, "singleton_instance", Looksee_singleton_instance, 1);
#if RUBY_VERSION < 190
  rb_define_method(mMRI, "source_location", Looksee_source_location, 1);
#endif
}
