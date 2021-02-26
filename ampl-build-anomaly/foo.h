#include <stdio.h>

#ifdef __cplusplus
extern "C" {
	void foo(); 
}
#else
void foo(); 
#endif

char* f1(char*);

int twox(int);
