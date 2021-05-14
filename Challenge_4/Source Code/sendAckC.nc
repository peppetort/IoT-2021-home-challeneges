/**
 *  Source file for implementation of module sendAckC in which
 *  the node 1 send a request to node 2 until it receives a response.
 *  The reply message contains a reading from the Fake Sensor.
 *
 *  @author Luca Pietro Borsani
 */

#include "sendAck.h"
#include "Timer.h"

module sendAckC {

  uses {
  /****** INTERFACES *****/
	interface Boot; 
	
    //interfaces for communication
    interface Packet;
    interface Receive;
    interface AMSend;
    interface SplitControl;
    
	//interface for timer
	interface Timer<TMilli> as MilliTimer;
	
    //other interfaces, if needed
    interface PacketAcknowledgements;
	
	//interface used to perform sensor reading (to get the value from a sensor)
	interface Read<uint16_t>;
  }

} implementation {

  uint8_t counter=0;
  uint8_t rec_id;
  bool locked;
  message_t packet;

  void sendReq();
  void sendResp();
  
  
  //***************** Send request function ********************//
  void sendReq() {
	/* This function is called when we want to send a request
	 *
	 * STEPS:
	 * 1. Prepare the msg
	 * 2. Set the ACK flag for the message using the PacketAcknowledgements interface
	 *     (read the docs)
	 * 3. Send an UNICAST message to the correct node
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	 
	msg_t* msg = (msg_t*)call Packet.getPayload(&packet, sizeof(msg_t));
	if (msg == NULL){
  			return;
  	}
  	call PacketAcknowledgements.requestAck(&packet);
  	msg->msg_type = 1;
  	msg->msg_counter = counter;
  	
  	if (call AMSend.send(2, &packet, sizeof(msg_t)) == SUCCESS) {
		locked = TRUE;
		dbg("radio_pack","Payload REQ Sent\n" );
		dbg_clear("radio_pack", "\t type: %u \n ", msg->msg_type);
		dbg_clear("radio_pack", "\t counter: %u \n", msg->msg_counter);
    }
 }        

  //****************** Task send response *****************//
  void sendResp() {
  	/* This function is called when we receive the REQ message.
  	 * Nothing to do here. 
  	 * `call Read.read()` reads from the fake sensor.
  	 * When the reading is done it raise the event read one.
  	 */
	call Read.read();
  }

  //***************** Boot interface ********************//
  event void Boot.booted() {
	dbg("boot","Application booted.\n");
    call SplitControl.start();
  }

  //***************** SplitControl interface ********************//
  event void SplitControl.startDone(error_t err){
   	if(err == SUCCESS) {
    	dbg("radio", "Radio on!\n");
		if (TOS_NODE_ID > 0){
           	call MilliTimer.startPeriodic( 1000 );
  		}
    }else{
	//dbg for error
	call SplitControl.start();
    }
  }
  
  event void SplitControl.stopDone(error_t err){
    /* Fill it ... */
  }

  //***************** MilliTimer interface ********************//
  event void MilliTimer.fired() {	
  	if(locked){
  		return;
  	}else{
  		if(TOS_NODE_ID == 1){
  			sendReq();
  			counter++;			
  		}
  	}	
  }
  

  //********************* AMSend interface ****************//
  event void AMSend.sendDone(message_t* buf,error_t err) {
	/* This event is triggered when a message is sent 
	 *
	 * STEPS:
	 * 1. Check if the packet is sent
	 * 2. Check if the ACK is received (read the docs)
	 * 2a. If yes, stop the timer. The program is done
	 * 2b. Otherwise, send again the request
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	if (&packet == buf) {
      locked = FALSE;
      if(TOS_NODE_ID == 1 && (call PacketAcknowledgements.wasAcked(&packet))){
      dbg("radio_pack","ACK received...stopping timer \n");
      	call MilliTimer.stop();
      }else if(TOS_NODE_ID == 2 && (call PacketAcknowledgements.wasAcked(&packet))){
      dbg("radio_pack","ACK received\n");
      }
    }
	 
  }

  //***************************** Receive interface *****************//
  event message_t* Receive.receive(message_t* buf,void* payload, uint8_t len) {
	/* This event is triggered when a message is received 
	 *
	 * STEPS:
	 * 1. Read the content of the message
	 * 2. Check if the type is request (REQ)
	 * 3. If a request is received, send the response
	 * X. Use debug statements showing what's happening (i.e. message fields)
	 */
	if(TOS_NODE_ID == 2){
		if (len != sizeof(msg_t)) {
    		return buf;
    	}else {
    		msg_t* msg = (msg_t*)payload;
    		if(msg->msg_type == 1){	
    			counter = msg->msg_counter;
    			sendResp();
    			
    			dbg("radio_pack","Payload REQ Received\n" );
      			dbg_clear("radio_pack", "\t type: %u \n ", msg->msg_type);
	  			dbg_clear("radio_pack", "\t counter: %u \n", msg->msg_counter);
    			
    			return buf;
    		}
    	}
    }else if(TOS_NODE_ID == 1){
    msg_t* msg = (msg_t*)payload;
    dbg("radio_pack","Payload RESP Received\n" );
    dbg_clear("radio_pack", "\t type: %u \n ", msg->msg_type);
	dbg_clear("radio_pack", "\t counter: %u \n", msg->msg_counter);
	dbg_clear("radio_pack", "\t value: %u \n", msg->msg_value);
	}
  }
  
  //************************* Read interface **********************//
  event void Read.readDone(error_t result, uint16_t data) {
	/* This event is triggered when the fake sensor finish to read (after a Read.read()) 
	 *
	 * STEPS:
	 * 1. Prepare the response (RESP)
	 * 2. Send back (with a unicast message) the response
	 * X. Use debug statement showing what's happening (i.e. message fields)
	 */
	msg_t* msg = (msg_t*)call Packet.getPayload(&packet, sizeof(msg_t));
	if (msg == NULL){
  			return;
  	}
  	call PacketAcknowledgements.requestAck(&packet);
  	msg->msg_type = 2;
  	msg->msg_value = data;
  	msg->msg_counter = counter;
  	
  	
  	if (call AMSend.send(1, &packet, sizeof(msg_t)) == SUCCESS) {
		locked = TRUE;
		dbg("radio_pack","Payload RESP Sent\n" );
		dbg_clear("radio_pack", "\t type: %u \n ", msg->msg_type);
		dbg_clear("radio_pack", "\t counter: %u \n", msg->msg_counter);
		dbg_clear("radio_pack", "\t value: %u \n", msg->msg_value);
    }
}
}

