/* MRI 1.9 does not install node.h.  This is the part we need. */

typedef struct RNode {
    unsigned long flags;
    char *nd_file;
    union {
	struct RNode *node;
	ID id;
	VALUE value;
	VALUE (*cfunc)(ANYARGS);
	ID *tbl;
    } u1;
    union {
	struct RNode *node;
	ID id;
	long argc;
	VALUE value;
    } u2;
    union {
	struct RNode *node;
	ID id;
	long state;
	struct global_entry *entry;
	long cnt;
	VALUE value;
    } u3;
} NODE;

#define nd_body  u2.node
#define nd_noex  u3.id

#define NOEX_PUBLIC    0x00
#define NOEX_PRIVATE   0x02
#define NOEX_PROTECTED 0x04
#define NOEX_MASK      0x06
