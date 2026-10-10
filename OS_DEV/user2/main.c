#include "lib.h"
#include "stdint.h"

int main(void)
{   
    //char* p = (char*)0xffff800000200200;
    //*p =1;
    printf("process2\n");
    sleepu(200);

    for(int i = 0; i < 10; i++)
    {
	    printf("%d", i);
    }
    return 0;

}
