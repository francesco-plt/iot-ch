/**
 *  Configuration file for wiring of sendAckC module to other common 
 *  components needed for proper functioning
 *
 *  @author Luca Pietro Borsani
 */

#include "Ch4C.h"

configuration AppCh4C {}

implementation {


  /****** COMPONENTS *****/
  components MainC, Ch4C as App
  components LedsC, ActiveMessageC;
  //add the other components here
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components new TimerMilliC();

  /****** INTERFACES *****/

  //Boot interface
  App.Boot -> MainC.Boot;

  /****** Wire the other interfaces down here *****/
  
  //Send and Receive interfaces
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;
  App.AckMgmt -> PacketAcknowledgements;
  
  //Radio Control
  App.AMControl -> ActiveMessageC.PacketAcknowledgements;

  //Interfaces to access package fields
  App.Packet -> AMSenderC;

  //Timer interface
  App.MilliTimer -> TimerMilliC;

  //Fake Sensor read
  App.Read -> FakeSensorC;

}

