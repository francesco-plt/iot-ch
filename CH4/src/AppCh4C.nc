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
  components MainC, Ch4C as App;
  components LedsC, ActiveMessageC, LocalTimeMilliC;
  //add the other components here
  components new AMSenderC(AM_RADIO_COUNT_MSG);
  components new AMReceiverC(AM_RADIO_COUNT_MSG);
  components new TimerMilliC();
  components new FakeSensorC();

  /****** INTERFACES *****/

  //Boot interface
  App.Boot -> MainC.Boot;

  /****** Wire the other interfaces down here *****/

  //Send and Receive interfaces
  App.Receive -> AMReceiverC;
  App.AMSend -> AMSenderC;

  App.AMControl -> ActiveMessageC;
  App.PacketAcknowledgements -> ActiveMessageC;

  //Interfaces to access package fields
  App.Packet -> AMSenderC;

  //Timer interface
  App.MilliTimer -> TimerMilliC;
  App.LocalTime -> LocalTimeMilliC;

  //Fake Sensor read
  App.Read -> FakeSensorC;
}
