#include "printf.h"
#include <inttypes.h>
#define T_INT 60000

uint8_t rem;
uint8_t count;
uint32_t pcode;

module Ch3
{
  uses interface Boot;
  uses interface Timer<TMilli>;
  uses interface Leds;
}
implementation
{
  event void Boot.booted()
  {
    count = 0;
    pcode = 10783751;
    // testing that the boot event is working
    printf("Booted\n");
    printfflush();
    call Timer.startPeriodic(T_INT); // 1 minute intervals
  }

  event void Timer.fired()
  {
    // just making sure the timer is working
    printf("DEBUG: The timer has fired [%ld]\n", count);
    printfflush();
    count = count + 1;

    // step of the ternary conversion of pcode
    printf("DEBUG: (pcode) [%ld] -> ", pcode);
    printfflush();
    rem = pcode % 3;
    pcode = pcode / 3;
    printf("[%ld], remainder %ld\n", pcode, remainder);
    printfflush();

    // according to the remainder of the iteration,
    //toggling the correspondent LED
    // if(remainder == 0)
    // {
    //   call Leds.led0Toggle();
    // }
    // else if(remainder == 1)
    // {
    //   call Leds.led1Toggle();
    // }
    // else if(remainder == 2)
    // {
    //   call Leds.led2Toggle();
    // } else {
    //   printf("DEBUG - ERROR: remainder is not 0, 1 or 2\n");
    //   printf("DEBUG - ERROR: remainder is %ld\n", remainder);
    //   printfflush();
    // }

    // bif the ternary conversion is done
    // (quotient = 0), stop the timer
    if(pcode == 0)
    {
      call Timer.stop();
    }
  }
}

