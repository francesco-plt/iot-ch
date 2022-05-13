/**
 *  @author Luca Pietro Borsani
 */

#ifndef CH4C_H
#define CH4C_H

//payload of the msg
typedef nx_struct resp_msg {
	nx_uint8_t type;
	nx_uint8_t counter_cpy;
	nx_uint8_t value;
} resp_msg_t;

typedef nx_struct req_msg {
	nx_uint8_t type;
	nx_uint8_t counter;
} req_msg_t;

#define REQ 1
#define RESP 2 

enum{
	AM_RADIO_COUNT_MSG = 6,
	TIMER_PERIOD_MILLI = 1000
};

#endif
