#include "bar.h"

#if defined(FIX) && defined(__cplusplus)
extern "C" int g1;
#else
extern int g1;
#endif

#ifdef FIX
extern char* f1(char*);
#else
extern int* f1(char*);
#endif

void bar(int x) {
	if(x<g1) {
		printf("%d is less than %d\n",x,g1);
	}
	else {	
		printf("%d is greater or equal than %d\n",x,g1);
	} 
	char* p = "text";
	f1(p);
}
