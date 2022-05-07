/*
	@author Francesco Pallotta - 2022
*/
#include "printf.h"
#include <inttypes.h>
#define T_INT 60000

module Ch3C {
  uses {
    interface Boot;
    interface Timer<TMilli>;
    interface Leds;
  }
}

implementation {

	uint32_t pers_code = 0;
	uint32_t dbg_flag = 1;	// 0: no debug, 1: debug
	uint32_t led0_state;
	uint32_t led1_state;
	uint32_t led2_state;

	uint32_t updateLedState(uint32_t status) {
		if(status == 0) {
			return 1;
		} else {
			return 0;
		}
	}


	event void Boot.booted() {
		pers_code = 10783751;
		
		// Set the LEDs to the initial state
		call Leds.led0Off();
		call Leds.led1Off();
		call Leds.led2Off();

		// the get() function from the Leds.nc interface does not work,
		// it always returns the same value. To circumevent this problem,
		// I'm tracking the status of the led manually.
		led0_state = 0;
		led1_state = 0;
		led2_state = 0;
		
		// start timer, hit every T_INT milliseconds
		call Timer.startPeriodic(T_INT);
  	}

	event void Timer.fired() {
  	
		uint32_t rem;
		
		// step of the ternary conversion of pcode
		rem = pers_code % 3;
		pers_code = pers_code / 3;

		// printing to mote output
		if(dbg_flag) {
			printf("DEBUG: remainder: %" PRIu32, rem);
		}
		// printfflush();

		// according to the remainder of the iteration,
		//toggling the correspondent LED
		if(rem == 0) {
			call Leds.led0Toggle();
			led0_state = updateLedState(led0_state);
			if(dbg_flag) {
				printf(", led0 toggled\n");
				printfflush();
			}
		}
		else if(rem == 1) {
			call Leds.led1Toggle();
			led1_state = updateLedState(led1_state);
			if(dbg_flag) {
				printf(", led1 toggled\n");
				printfflush();
			}
		}
		else if(rem == 2) {
			call Leds.led2Toggle();
			led2_state = updateLedState(led2_state);
			if(dbg_flag) {
				printf(", led2 toggled\n");
				printfflush();
			}
		}

		// sending led status as a string containing
		// a JSON dictionary to the mote output
		printf("{\"led0\": %" PRIu32 ", \"led1\": %" PRIu32 ", \"led2\": %" PRIu32 "}\n", led0_state, led1_state, led2_state);
		printfflush();

		// exit condition	  	
		if(0 == pers_code) {
			if(dbg_flag) {
				printf("DEBUG: done. exiting\n");
				printfflush();
			}
			call Timer.stop();
		}  	
  	}
}
