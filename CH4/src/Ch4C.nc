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
	uint8_t rec_id = 2;
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
				return;
			}

			/* 1. Preparing the msg
			(REQ) messages to be sent to mote #2
			containins:
			1. Message type: REQ
			2. An incremental counter */
			m->type = REQ;
			m->counter = counter;

			// 2. Setting the ACK flag for the message using the PacketAcknowledgements interface
			call PacketAcknowledgements.requestAck(&packet);

			// sending request
			if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(req_msg_t)) == SUCCESS) {
				dbg("Ch4C", "Ch4C: [%hhu] REQ packet sent.\n", counter);	
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
		dbg("boot","Application booted.\n");
		call AMControl.start();
	}


	//***************** SplitControl interface ********************//

	// after starting the radio we start the timer
	event void AMControl.startDone(error_t err){
    	if (err == SUCCESS) {
      		call MilliTimer.startPeriodic(TIMER_PERIOD_MILLI);
    	}
    	else {
	  		dbg("boot","Error starting the timer.\n");
      		call AMControl.start();
    	}
}
  
	event void AMControl.stopDone(error_t err){
    	// for now it does nothing
	}


	//***************** MilliTimer interface ********************//
  
	event void MilliTimer.fired() {

		counter++;
		dbg("Ch4C", "Ch4C: timer fired, counter now is %hhu.\n", counter);

		// sending the request
		dbg("Ch4C", "Ch4C: sending request.\n");
    	sendReq();
	}
  

	//********************* AMSend interface ****************//

	// This event is triggered when a message is sent
	event void AMSend.sendDone(message_t* buf,error_t err) {

		// 1. checking if the packet was sent
		if (err == SUCCESS) {
			dbg("Ch4C", "Ch4C: packet sent.\n");
			locked = FALSE;
		}

		// 2. checking if the ACK is received
		if(call PacketAcknowledgements.wasAcked(buf)) {

			dbg("Ch4C", "Ch4C: ACK received.\n");
			// 2a. if yes, stopping the timer according to my id
			if (counter == Y) {
				dbg("Ch4C", "Ch4C: %hhu-th iteration reached.\nStopping timer.\n", rec_id);
				call MilliTimer.stop();
			}
		} else {
			// 2b. else sending again the request
			sendReq();
		}
  	}


	//***************************** Receive interface *****************//

	// This event is triggered when a message is received
  	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
\
		dbg("Ch4C", "Received packet of length %hhu.\n", len);
		
		// checking that the packet has the right size
		if (len != sizeof(resp_msg_t)) {
			dbg("Ch4C", "Received packet of wrong size.\n");
		}
		else {
			// 1. reading the message
			resp_msg_t *m = (resp_msg_t*)payload;

			// 2. checking that the packet is a request
			if (m->type == REQ) {
				dbg("Ch4C", "Received request. sending response...\n");
				sendResp();
			}
			else {
				dbg("Ch4C", "Received packet of unknown type %hhu.\n", m->type);
			}
		}
  	}
  
  
	//************************* Read interface **********************//

	// This event is triggered when the fake sensor finishes to read (after a Read.read())
	event void Read.readDone(error_t result, uint16_t data) {

	// 1. preparing the response
	resp_msg_t* m = (resp_msg_t*)call Packet.getPayload(&packet, sizeof(resp_msg_t));
	if (m == NULL) {
		dbg("Ch4C", "Error getting the payload.\n");
		return;
	}
	m->type = RESP;
	m->counter_cpy = counter;
	m->value = data;
	// printing packet content
	dbg("Ch4C", "Ch4C: packet content: type %hhu, counter %hhu, data %hhu.\n", m->type, m->counter, m->data);

	// 2. sending back the response with a unicast message
	dbg("Ch4C", "Sending response.\n");
	call AMSend.send(rec_id, &packet, sizeof(resp_msg_t));
  }
}
