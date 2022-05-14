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

		// timer and time interfaces
		interface Timer<TMilli> as MilliTimer;
		interface LocalTime<TMilli>;

		//interface for the fake sensor
		interface Read<uint16_t>;
	}

} implementation {

	uint8_t X = 2;	// last digit + 1
	uint8_t Y = 83;	// middle numbers of Persona Code
	uint8_t counter = 0;
	am_addr_t mote2_id = 2;
	am_addr_t mote1_id = 1;
	bool locked;
	message_t packet;

	void sendReq();
	void sendResp();
  
  
	//***************** Send request function ********************//

	// This function is called when we want to send a request
	void sendReq() {

		if (locked) {
			dbgerror("CH4App", "CH4App:Cannot send request, radio unavalaible\n");
      		return;
		} else {
			req_msg_t* m = (req_msg_t*)call Packet.getPayload(&packet, sizeof(req_msg_t));
			if (m == NULL) {
				dbgerror("CH4App", "CH4App [Mote %d]: Packet.getPayload failed", TOS_NODE_ID);
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
			if (call AMSend.send(mote2_id, &packet, sizeof(req_msg_t)) == SUCCESS) {	
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
		dbg("boot", "boot: [%d] Application booted.\n", call LocalTime.get());
		call AMControl.start();
	}


	//***************** SplitControl interface ********************//

	// after starting the radio we start the timer
	event void AMControl.startDone(error_t err){
    	if (err == SUCCESS) {
			dbg("radio","[%d] Radio on on node %d!\n", call LocalTime.get(), TOS_NODE_ID);
			if(TOS_NODE_ID == 1){
				dbg("timer", "timer: [Mote %d] starting timer...\n", TOS_NODE_ID);
      			call MilliTimer.startPeriodic(TIMER_PERIOD_MILLI);
			}
    	}
    	else {
	  		dbgerror("boot", "boot: Error starting the radio.\n");
      		call AMControl.start();
    	}
	}
  
	// needed otherwise it will throw an error
	event void AMControl.stopDone(error_t err) {}


	//***************** MilliTimer interface ********************//
  
	event void MilliTimer.fired() {

		dbg("timer", "timer: [%d] timer fired, counter now is %hhu.\n\n", call LocalTime.get(), counter);
		counter++;

		// sending the request
    	if(TOS_NODE_ID == 1){
			sendReq();
		}
	}
  

	//********************* AMSend interface ****************//

	// This event is triggered when a message is sent
	event void AMSend.sendDone(message_t* buf,error_t err) {

		// 1. checking if the packet was sent
		if (&packet == buf) {
			locked = FALSE;
			dbg("CH4App", "CH4App [Mote %d]: [%hhu] REQ packet sent.\n", TOS_NODE_ID, counter);
		} else {
			dbgerror("CH4App", "CH4App: packet not sent.\n");
		}

		// 2. checking if the ACK is received
		if(call PacketAcknowledgements.wasAcked(buf)) {

			X  = X - 1;
			dbg("CH4App", "CH4App: ACK received, X is now %hhu\n", X);
			// 2a. if yes, stopping the timer according to my id
			if (X == 0) {
				dbg("CH4App", "CH4App: Stopping timer.\n");
				dbg("timer", "timer: timer stopped.\n");
				call MilliTimer.stop();
			}
		} else {
			// 2b. else sending again the request
			dbgerror("CH4App", "CH4App: ACK not received [%d]. Waiting for next timer call...\n", call PacketAcknowledgements.wasAcked(buf));
			// sendReq();
		}
  	}


	//***************************** Receive interface *****************//

	// This event is triggered when a message is received
  	event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {

		// 1. reading the message
		resp_msg_t *m = (resp_msg_t*)payload;
		
		dbg("CH4App", "CH4App: [node %d] Received packet of length %hhu.\n", len, TOS_NODE_ID);
		
		// checking that the packet has the right size
		// if (len != sizeof(resp_msg_t)) {
		// 	dbgerror("CH4App", "CH4App: Received packet of wrong size.\n");
		// 	return buf;
		// }

		// 2. checking that the packet is a request
		if (m->type != REQ) {
			dbg("CH4App", "CH4App: Received packet of unknown type %hhu.\n", m->type);
			return buf;
		}
		dbg("CH4App", "CH4App [Mote %d]:Request received\n", TOS_NODE_ID);
		// then sending response
		sendResp();

		return buf;
  	}
  
  
	//************************* Read interface **********************//

	// This event is triggered when the fake sensor finishes to read (after a Read.read())
	event void Read.readDone(error_t result, uint16_t data) {
	
	// 1. preparing the response
	resp_msg_t* m = (resp_msg_t*)call Packet.getPayload(&packet, sizeof(resp_msg_t));
	dbg("CH4App", "CH4App: [Mote %d] Read done.\n", TOS_NODE_ID);
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
	dbg("CH4App", "CH4App [Mote %d]: Sending response.\n", TOS_NODE_ID);
	call PacketAcknowledgements.requestAck(&packet);
	if (call AMSend.send(mote1_id, &packet, sizeof(resp_msg_t)) == SUCCESS) {	
		locked = TRUE;
	}
  }
}
