#include "Timer.h"
#include "printf.h"

module Ch3C @safe()
{
  uses interface Timer<TMilli> as Timer0;
  uses interface Leds;
  uses interface Boot;
}
implementation
{
  uint32_t count = 0;
  uint32_t pcode = 10783751;
  uint32_t remainder;

  event void Boot.booted()
  {
    call Timer0.startPeriodic( 60000 ); // 1 minute
  }

  event void Timer0.fired()
  {
    printf("DEBUG: The timer has fired [%ld]\n", count);
    count = count + 1;

    // step of the ternary conversion of pcode
    printf("DEBUG: (pcode) [%ld] -> ", pcode);
    remainder = pcode % 3;
    printf("[%ld], remainder %ld\n", pcode, remainder);
    printfflush();

    // according to the remainder of the iteration,
    //toggling the correspondent LED
    if(remainder == 0)
    {
      call Leds.led0Toggle();
    }
    else if(remainder == 1)
    {
      call Leds.led1Toggle();
    }
    else if(remainder == 2)
    {
      call Leds.led2Toggle();
    } else {
      printf("DEBUG - ERROR: remainder is not 0, 1 or 2\n");
      printf("DEBUG - ERROR: remainder is %ld\n", remainder);
      printfflush();
    }
  }
}

