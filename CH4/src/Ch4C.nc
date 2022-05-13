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
	interface AckMgmt; 

	// control interface
	interface SplitControl as AMControl;

	// timer and leds interfaces
	interface Timer<TMilli> as TimerMilliC;
    interface Leds;
	
	//interface for the fake sensor
	interface Read<uint16_t>;
  }

} implementation {

  uint8_t X = 2;	// last digit + 1
  uint8_t Y = 83;	// middle numbers of Persona Code
  uint8_t counter = 0;
  // uint8_t rec_id;
  message_t packet;

  void sendReq();
  void sendResp();
  
  
  //***************** Send request function ********************//

  // This function is called when we want to send a request
  void sendReq() {

	// 1. Prepare the msg
	packet.type = REQ;
	packet.id = counter;
	packet.data = 0;

	// 2. Set the ACK flag for the message using the PacketAcknowledgements interface
	AckMgmt.requestAck(packet);

	// 3. Send an UNICAST message to the correct node
	if (locked) {
      return;
    } else {
      ch4_msg_t* m = (radio_count_ch4_msg_t*)call Packet.getPayload(&packet, sizeof(ch4_msg_t));
      if (m == NULL) {
	    return;
      }

      m->counter = counter;
	  // sending request
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(ch4_msg_t)) == SUCCESS) {
	      dbg("Ch4C", "Ch4C: packet sent.\n", counter);	
	      locked = TRUE;
      }
    }
 }        


  //****************** Task send response *****************//

  // This function is called when we receive the REQ message
  void sendResp() {

	//read from the fake sensor
	call Read.read();

	// raising the event read done
	// the following function sends
	// the response packet
	call Read.readDone();
  }


  //***************** Boot interface ********************//

  event void Boot.booted() {
	dbg("boot","Application booted.\n");
	call AMControl.start();
  }


  //***************** SplitControl interface ********************//

  // after starting the radio we start the timer
  event void SplitControl.startDone(error_t err){
    if (err == SUCCESS) {
      call MilliTimer.startPeriodic(TIMER_PERIOD_MILLI);
    }
    else {
	  dbg("boot","Error starting the timer.\n");
      call AMControl.start();
    }
  }
  
  event void SplitControl.stopDone(error_t err){
    // for now it does nothing
  }


  //***************** MilliTimer interface ********************//
  
  event void MilliTimer.fired() {

	counter++;
	dbg("Ch4C", "Ch4C: timer fired, counter now is %hu.\n", counter);

	// checking if radio is available
    if (locked) {
      return;
    } else {
      ch4_msg_t* m = (radio_count_ch4_msg_t*)call Packet.getPayload(&packet, sizeof(ch4_msg_t));
      if (m == NULL) {
	    return;
      }

      m->counter = counter;
	  // sending request
      if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(ch4_msg_t)) == SUCCESS) {
	      dbg("Ch4C", "Ch4C: packet sent.\n", counter);	
	      locked = TRUE;
      }
    }
  }
  

  //********************* AMSend interface ****************//

  // This event is triggered when a message is sent
  event void AMSend.sendDone(message_t* buf,error_t err) {

	// 1. checking if the packet was sent
	if (&packet == bufPtr) {
		dbg("Ch4C", "Ch4C: packet sent.\n");
		locked = FALSE;
	}

	// 2. checking if the ACK is received
	if(AckMgmt.wasAcked(buf)) {

		dbg("Ch4C", "Ch4C: ACK received.\n");
		rec_id = buf->counter;
		// 2a. if yes, stopping the timer according to my id
		if (rec_id == Y) {
			dbg("Ch4C", "Ch4C: %hu-th iteration reached.\nStopping timer.\n", rec_id);
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

	dbg("Ch4C", "Received packet of length %hhu.\n", len);
	
	// checking that the packet has the right size
	if (len != sizeof(ch4_msg_t)) {
		dbg("Ch4C", "Received packet of wrong size.\n");
		return bufPtr;
	}
    else {
		// 1. reading the message
		ch4_msg_t *m = (ch4_msg_t*)payload;

		// 2. checking that the packet is a request
		if (m->type == REQ) {
			dbg("Ch4C", "Received request. sending response...\n");
			sendResp();
		}
		else {
			dbg("Ch4C", "Received packet of unknown type %hhu.\n", m->type);
			return bufPtr;
		}
	}
  }
  
  
  //************************* Read interface **********************//

  // This event is triggered when the fake sensor finishes to read (after a Read.read())
  event void Read.readDone(error_t result, uint16_t data) {

	// 1. preparing the response
	ch4_msg_t* m = (ch4_msg_t*)call Packet.getPayload(&packet, sizeof(ch4_msg_t));
	if (m == NULL) {
		dbg("Ch4C", "Error getting the payload.\n");
		return;
	}
	m->type = RESP;
	m->counter = counter;
	m->data = data;
	// printing packet content
	dbg("Ch4C", "Ch4C: packet content: type %hhu, counter %hhu, data %hu.\n", m->type, m->counter, m->data);

	// 2. sending back the response
	dbg("Ch4C", "Sending response.\n");
	call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(ch4_msg_t));
  }
}
