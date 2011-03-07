struct BLOCK {
  NODE *var;
  NODE *body;
  VALUE self;
  struct FRAME frame;
  struct SCOPE *scope;
  VALUE klass;
  NODE *cref;
  int iter;
  int vmode;
  int flags;
  int uniq;
  struct RVarmap *dyna_vars;
  VALUE orig_thread;
  VALUE wrapper;
  VALUE block_obj;
  struct BLOCK *outer;
  struct BLOCK *prev;
};

struct METHOD {
  VALUE klass, rklass;
  VALUE recv;
  ID id, oid;
  int safe_level;
  NODE *body;
};
