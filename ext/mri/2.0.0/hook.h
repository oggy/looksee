# define ID_ALLOCATOR 1
typedef enum {
    RUBY_HOOK_FLAG_SAFE    = 0x01,
    RUBY_HOOK_FLAG_DELETED = 0x02,
    RUBY_HOOK_FLAG_RAW_ARG = 0x04
} rb_hook_flag_t;

typedef struct rb_event_hook_struct {
    rb_hook_flag_t hook_flags;
    rb_event_flag_t events;
    rb_event_hook_func_t func;
    VALUE data;
    struct rb_event_hook_struct *next;
} rb_event_hook_t;
