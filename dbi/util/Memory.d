module dbi.util.Memory;

import tango.stdc.stdlib;

struct Allocator
{
	void* delegate(size_t x) allocate = delegate void*(size_t x) {
		return malloc(x);
	};
	void delegate(void* p) free = delegate void(void* p) {
		free(p);
	};
}
