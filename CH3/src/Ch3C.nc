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
	uint32_t led0_state;
	uint32_t led1_state;
	uint32_t led2_state;

	// turn off leds
	call Leds.led0Off();
	call Leds.led1Off();
	call Leds.led2Off();
	led0_state = 0;
	led1_state = 0;
	led2_state = 0;
  	
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
	  led0_state = 1;
	  printf(", led0 toggled\n");
	  printfflush();
    }
    else if(rem == 1)
    {
      call Leds.led1Toggle();
	  led1_state = 1;
	  printf(", led1 toggled\n");
	  printfflush();
    }
    else if(rem == 2)
    {
      call Leds.led2Toggle();
	  led2_state = 1;
	  printf(", led2 toggled\n");
	  printfflush();
    } else {
      printf("DEBUG: ERROR - remainder is not 0, 1 or 2\n");
      printfflush();
    }

	// sending led status as a string containing
	// a JSON dictionary to the mote output
	printf("{\"led0\": %" PRIu32 ", \"led1\": %" PRIu32 ", \"led2\": %" PRIu32 "}\n", led0_state, led1_state, led2_state);
	printfflush();

	// exit condition	  	
  	if(0 == pers_code) {
		printf("DEBUG: done. exiting\n");
  		call Timer.stop();
  	}  	
  }
}
