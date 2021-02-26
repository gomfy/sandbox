#include "foo.h"

#if defined(FIX) && defined(__cplusplus)
extern "C" { 
	int g1 = 10;
}
#else
extern int g1 = 10;
#endif

void foo() {
    printf("The value of global variable g1 is: %d\n", g1);
// Below for testing MSVC's runtime checker 
// by using an uninitialized value k in a function
    int k;
    int twok = twox(k);
}

char* f1(char* cptr) {
	return cptr;
}

int twox(int k) {
	return 2*k;
}

