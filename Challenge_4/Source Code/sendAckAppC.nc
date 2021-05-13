/**
 *  Configuration file for wiring of sendAckC module to other common 
 *  components needed for proper functioning
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"

configuration sendAckAppC {}

implementation {


/****** COMPONENTS *****/
  components MainC, sendAckC as App;
  components new AMReceiverC(AM_SEND_MSG);
  components new AMSenderC(AM_SEND_MSG);
  components new TimerMilliC() as milli_t;
  components ActiveMessageC;
  components new FakeSensorC();

/****** INTERFACES *****/
  //Boot interface
  App.Boot -> MainC.Boot;

  /****** Wire the other interfaces down here *****/
  //Send and Receive interfaces
  App.AMSend -> AMSenderC;
  App.Receive -> AMReceiverC;
  
  //Radio Control
  App.SplitControl -> ActiveMessageC;
  
  //Interfaces to access package fields
  App.Packet -> AMSenderC;
  
  //Timer interface
  App.MilliTimer -> milli_t;
  
  //Fake Sensor read
  App.Read -> FakeSensorC;
  
  App.PacketAcknowledgements -> AMSenderC;

}

