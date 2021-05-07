#include "Timer.h"
#include "foo.h"
#include "printf.h"

module fooC @safe() {
  uses {
    interface Leds;
    interface Boot;
    interface Receive;
    interface AMSend;
    interface Timer<TMilli> as MilliTimer;
    interface SplitControl as AMControl;
    interface Packet;
  }
}
implementation {

  message_t packet;

  bool locked;
  uint16_t counter = 0;
  
  //To keep tack of leds status (since get not works)
  bool led0 = 0;
  bool led1 = 0;
  bool led2 = 0;
  
  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
    	if(TOS_NODE_ID == 1){
    		call MilliTimer.startPeriodic(1000); // 1Hz
    	}else if(TOS_NODE_ID == 2){
    		call MilliTimer.startPeriodic(1000/3); // 3Hz
    	}else if(TOS_NODE_ID == 3){
    		call MilliTimer.startPeriodic(1000/5); // 5Hz
    	}
    }
    else {
      call AMControl.start();
    }
  }

  event void AMControl.stopDone(error_t err) {
    // do nothing
  }
  
  event void MilliTimer.fired() {
  	if(locked){
  		return;
  	}else{
  		radio_count_msg_t* rcm = (radio_count_msg_t*)call Packet.getPayload(&packet, sizeof(radio_count_msg_t));
  		if (rcm == NULL){
  			return;
  		}
  		rcm->id = TOS_NODE_ID;
  		rcm->counter = counter;
  		printf("SEND -> %u\n",counter);
        
    if (call AMSend.send(AM_BROADCAST_ADDR, &packet, sizeof(radio_count_msg_t)) == SUCCESS) {
		locked = TRUE;
    	}
      }
     }
  
  
  event message_t* Receive.receive(message_t* bufPtr, void* payload, uint8_t len) {
    if (len != sizeof(radio_count_msg_t)) {
    	return bufPtr;
    }else {
      radio_count_msg_t* rcm = (radio_count_msg_t*)payload;
      
      counter++;
      
      	//Id control
  		if(rcm->id == 1){
  			call Leds.led0Toggle();
  			if(led0 == 0){
  				led0 = 1;
  			}else{
  				led0 = 0;
  			}
  		}else if(rcm->id == 2){
  			call Leds.led1Toggle();
  			if(led1 == 0){
  				led1 = 1;
  			}else{
  				led1 = 0;
  			}
  		}else if(rcm->id == 3){
  			call Leds.led2Toggle();
  			if(led2 == 0){
  				led2 = 1;
  			}else{
  				led2 = 0;
  			}
  		}
  		
  		//Counter control
  		if((rcm->counter % 10) == 0){
  			call Leds.led0Off();
  			call Leds.led1Off();
  			call Leds.led2Off();
  			led0 = 0;
  			led1 = 0;
  			led2 = 0;
  		}
  		
  		printf("RECEIVE -> %u from mote: %u\nUPDATE COUNTER: %u\nLEDS: %u%u%u\n", rcm->counter, rcm->id, counter, led2,led1,led0);
  		
  		//To get required values
  		/*
  		if(TOS_NODE_ID == 2){
  			printf("### %u ###\n%u%u%u\n", counter, led2,led1,led0); 
  		}
  		*/
  		
  		return bufPtr;
  		

    }
  }	


  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

} 
