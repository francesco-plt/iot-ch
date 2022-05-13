/**
 *  Source file for implementation of module Ch4C in which
 *  the node 1 send a request to node 2 until it receives a response.
 *  The reply message contains a reading from the Fake Sensor.
 *
 *  @author Luca Pietro Borsani
 */

#include "Ch4C.h"
#include "Timer.h"

module Ch4C {

	uses {
		/****** INTERFACES *****/
		interface Boot; 

		// packet manipulation interfaces
		interface Packet; 
		interface AMSend;
		interface Receive;
		interface PacketAcknowledgements; 

		// control interface
		interface SplitControl as AMControl;

		// timer and leds interfaces
		interface Timer<TMilli> as MilliTimer;
		interface Leds;

		//interface for the fake sensor
		interface Read<uint16_t>;
	}

} implementation {

	uint8_t X = 2;	// last digit + 1
	uint8_t Y = 83;	// middle numbers of Persona Code
	uint8_t counter = 0;
	uint8_t mote2_id = 2;
	uint8_t mote1_id = 1;
	bool locked;
	message_t packet;

	void sendReq();
	void sendResp();
  
  
	//***************** Send request function ********************//

	// This function is called when we want to send a request
	void sendReq() {

		if (locked) {
      		return;
		} else {
			req_msg_t* m = (req_msg_t*)call Packet.getPayload(&packet, sizeof(req_msg_t));
			if (m == NULL) {
				dbgerror("CH4App", "CH4App [Mote 1]: Packet.getPayload failed");
			}

			/* 1. Preparing the msg
			(REQ) messages to be sent to mote #2
			containins:
			1. Message type: REQ
			2. An incremental counter */
			counter++;
			m->type = REQ;
			m->counter = counter;

			// 2. Setting the ACK flag for the message using the PacketAcknowledgements interface
			call PacketAcknowledgements.requestAck(&packet);

			// sending request
			if (call AMSend.send(mote1_id, &packet, sizeof(req_msg_t)) == SUCCESS) {
				dbg("CH4App", "CH4App [Mote 1]: [%hhu] REQ packet sent.\n", counter);	
				locked = TRUE;
			}
		}
	}        


	//****************** Task send response *****************//

	// This function is called when we receive the REQ message
	void sendResp() {
		/* This function is called when we receive the REQ message.
		* Nothing to do here. 
		* `call Read.read()` reads from the fake sensor.
		* When the reading is done it raises the event read done.
		*/
		call Read.read();
	}


	//***************** Boot interface ********************//

	event void Boot.booted() {
		dbg("boot", "boot: Application booted.\n");
		call AMControl.start();
	}


	//***************** SplitControl interface ********************//

	// after starting the radio we start the timer
	event void AMControl.startDone(error_t err){
    	if (err == SUCCESS) {
			// looks like tinyOS already prints this by itself
			// dbg("radio", "radio: Radio booted.\n");
      		call MilliTimer.startPeriodic(TIMER_PERIOD_MILLI);
    	}
    	else {
	  		dbgerror("boot", "boot: Error starting the timer.\n");
      		call AMControl.start();
    	}
}
  
	// needed otherwise it will throw an error
	event void AMControl.stopDone(error_t err) {}


	//***************** MilliTimer interface ********************//
  
	event void MilliTimer.fired() {

		counter++;
		dbg("CH4App", "CH4App: timer fired, counter now is %hhu.\n\n", counter);

		// sending the request
    	sendReq();
	}
  

	//********************* AMSend interface ****************//

	// This event is triggered when a message is sent
	event void AMSend.sendDone(message_t* buf,error_t err) {

		// 1. checking if the packet was sent
		if (err == SUCCESS) {
			locked = FALSE;
		} else {
			dbgerror("CH4App", "CH4App: packet not sent.\n");
		}

		// 2. checking if the ACK is received
		if(call PacketAcknowledgements.wasAcked(buf)) {

			dbg("CH4App", "CH4App: ACK received.\n");
			// 2a. if yes, stopping the timer according to my id
			if (counter == Y) {
				dbg("CH4App", "CH4App: %hhu-th iteration reached.\nStopping timer.\n", counter);
				call MilliTimer.stop();
			}
		} else {
			// 2b. else sending again the request
			dbgerror("CH4App", "CH4App: ACK not received. Sending again the request...\n");
			sendReq();
		}
  	}


	//***************************** Receive interface *****************//

	// This event is triggered when a message is received
  	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
\
		dbg("CH4App", "CH4App: Received packet of length %hhu.\n", len);
		
		// checking that the packet has the right size
		if (len != sizeof(resp_msg_t)) {
			dbgerror("CH4App", "CH4App: Received packet of wrong size.\n");
		}
		else {
			// 1. reading the message
			resp_msg_t *m = (resp_msg_t*)payload;

			// 2. checking that the packet is a request
			if (m->type == REQ) {
				dbg("CH4App", "CH4App [Mote 2]:Request received\n");
				sendResp();
			}
			else {
				dbg("CH4App", "CH4App: Received packet of unknown type %hhu.\n", m->type);
			}
		}
  	}
  
  
	//************************* Read interface **********************//

	// This event is triggered when the fake sensor finishes to read (after a Read.read())
	event void Read.readDone(error_t result, uint16_t data) {

	// 1. preparing the response
	resp_msg_t* m = (resp_msg_t*)call Packet.getPayload(&packet, sizeof(resp_msg_t));
	if (m == NULL) {
		dbg("CH4App", "CH4App: readDone - error getting the payload.\n");
		return;
	}
	m->type = RESP;
	m->counter_cpy = counter;
	m->value = data;
	// printing packet content
	dbg("CH4App", "CH4App: packet content - type %hhu, counter %hhu, data %hhu.\n", m->type, m->counter_cpy, m->value);

	// 2. sending back the response with a unicast message
	dbg("CH4App", "CH4App [Mote 2]: Sending response.\n");
	call AMSend.send(mote2_id, &packet, sizeof(resp_msg_t));
  }
}
