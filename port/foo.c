#include "foo.h"

void foo(const char* fn) {
	remove(fn);
#ifdef _WIN32
	rmdir(fn);
#endif
}


