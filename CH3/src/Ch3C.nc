#include "printf.h"
#include <inttypes.h>
#define T_INT 60000

/*
 * Library function call Leds.get(), defined here https://github.com/tinyos/tinyos-main/blob/master/tos/interfaces/Leds.nc#L117,
 * does not return the expected state of the LEDs. It always returns 7,
 * even when the simulator shows some LEDs rurned off.
 * Due to this impossibility to query the LED state, the state
 * is explicitly represented in the code and set at every iteration.
 * This allows reading the state without querying the interface.
 */

module Ch3C {
  uses {
    interface Boot;
    interface Timer<TMilli>;
    interface Leds;
  }
}

implementation {

	uint32_t pers_code = 0;

  event void Boot.booted() {
 	pers_code = 10783751;
  	
	// Set the LEDs to the initial state
	call Leds.led0Off();
	call Leds.led1Off();
	call Leds.led2Off();
  	
  	// start timer, hit every T_INT milliseconds
    call Timer.startPeriodic(T_INT);
  }

  event void Timer.fired() {
  	
	uint32_t rem;

	// turn off leds
	call Leds.led0Off();
	call Leds.led1Off();
	call Leds.led2Off();
  	
	// step of the ternary conversion of pcode
  	rem = pers_code % 3;
  	pers_code = pers_code / 3;

	// printing to mote output
	printf("DEBUG: remainder: %" PRIu32, rem);
	// printfflush();

	// according to the remainder of the iteration,
    //toggling the correspondent LED
    if(rem == 0)
    {
      call Leds.led0Toggle();
	  printf(", led0 toggled\n");
	  printfflush();
    }
    else if(rem == 1)
    {
      call Leds.led1Toggle();
	  printf(", led1 toggled\n");
	  printfflush();
    }
    else if(rem == 2)
    {
      call Leds.led2Toggle();
	  printf(", led2 toggled\n");
	  printfflush();
    } else {
      printf("DEBUG - ERROR: remainder is not 0, 1 or 2\n");
      printfflush();
    }

	// exit condition	  	
  	if(0 == pers_code) {
		printf("DEBUG: done. exiting\n");
  		call Timer.stop();
  	}  	
  }
}
