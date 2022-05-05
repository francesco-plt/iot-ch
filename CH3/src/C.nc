#include "math.h"
#include "printf.h"

module C
{
  uses interface Boot;
  uses interface Timer<TMilli>;
  uses interface Leds;
}
implementation
{
  uint8_t remainder;
  uint8_t count = 0;
  uint16_t minute = 60000;
  uint32_t pcode = 10783751;

  event void Boot.booted()
  {
    // testing that the boot event is working
    printf("Booted\n");
    call Timer.startPeriodic( minute ); // 1 minute
  }

  event void Timer.fired()
  {
    printf("DEBUG: The timer has fired [%ld]\n", count);
    count = count + 1;

    // step of the ternary conversion of pcode
    printf("DEBUG: (pcode) [%ld] -> ", pcode);
    remainder = pcode % 3;
    pcode = floor(pcode / 3);
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

    // bif the ternary conversion is done
    // (quotient = 0), stop the timer
    if(pcode == 0)
    {
      call Timer.stop();
    }
  }
}

