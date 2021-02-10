#include "foo.h"

#ifdef EXTERNCDEF
extern "C" int g1 = 10;
#else
extern int g1 = 10;
#endif

void foo() {
    printf("The value of global variable g1 is: %d\n", g1);
}
