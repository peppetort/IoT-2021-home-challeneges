#include "Timer.h"
#include "foo.h"
#include "printf.h"

#define MEMORY 4

module fooC @safe() {
  uses {
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
  uint32_t msg_number = 0;
  
  uint8_t near_motes_ids[MEMORY];
  uint8_t near_motes_counters[MEMORY];
  uint32_t near_motes_msgs_number[MEMORY];
  

  event void Boot.booted() {
    call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
    	uint8_t i = 0;
    	
    	
    	//Init array to keep track of near motes with default values
    	for(i=0;i<MEMORY;i++){
    		//Mote ID
    		near_motes_ids[i] = 0;
    		//Mote counter for messages received
    		near_motes_counters[i] = 0;
    		//Msg counter 
    		near_motes_msgs_number[i] = 0;
    	}
    	
    	
    	call MilliTimer.startPeriodic(500); // 2Hz
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
  		msg_number++;
  		rcm->id = TOS_NODE_ID;
  		rcm->msg_number = msg_number;
  		printf("(%lu) SEND\n", msg_number);
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
      
      uint8_t i = 0;
      bool is_in_memory = FALSE;
      
      //Check if the node ID contained in received message is already in our memory
      for(i=0;i<MEMORY && is_in_memory == FALSE;i++){
      	if(near_motes_ids[i] == rcm->id){
      		is_in_memory = TRUE;
      		//Checking if the message is the expected one
      		if(near_motes_msgs_number[i] != rcm->msg_number-1){
      		    printf("(%lu) RESET COUNTER for mote %u. Expected %lu received %lu\n", rcm->msg_number,  rcm->id, near_motes_msgs_number[i]+1, rcm->msg_number);
      			near_motes_counters[i] = 1;
      			near_motes_msgs_number[i] = rcm->msg_number;
      		}else{
      			near_motes_msgs_number[i]++;
      			
      			if(near_motes_counters[i] == 9){
      				near_motes_counters[i]++;
      				printf("(%lu) ALARM %u messages received =>mote %u close to mote %u\n", rcm->msg_number, near_motes_counters[i], TOS_NODE_ID, rcm->id);
      			}else if(near_motes_counters[i] < 9){
      				near_motes_counters[i]++;
      				printf("(%lu) COUTER UPDATETD for mote %u. counter %u\n", rcm->msg_number, rcm->id, near_motes_counters[i]);
      			}
      		}
      	}
      }
      
      if(is_in_memory == FALSE){
      	printf("(%lu) FIRST MESSAGE from mote %u\n", rcm->msg_number, rcm->id);
      	for(i=0;i<MEMORY;i++){
      		if(near_motes_ids[i] == 0){
      			near_motes_ids[i] = rcm->id;
      			near_motes_counters[i] = 1;
      			near_motes_msgs_number[i] = rcm->msg_number;
      			break;
      		}
      	}
      }
      
     
  		
  		return bufPtr;
  		
    }
  }	


  event void AMSend.sendDone(message_t* bufPtr, error_t error) {
    if (&packet == bufPtr) {
      locked = FALSE;
    }
  }

}
