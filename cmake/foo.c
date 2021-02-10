#include "foo.h"

#ifdef FIX
extern "C" int g1 = 10;
#else
extern int g1 = 10;
#endif

void foo() {
    printf("The value of global variable g1 is: %d\n", g1);
}

char* f1(char* cptr) {
	return cptr;
}

