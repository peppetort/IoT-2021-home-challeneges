/**
 *  @author Luca Pietro Borsani
 */

#ifndef SENDACK_H
#define SENDACK_H

#define REQ 1
#define RESP 2 

//payload of the msg
typedef nx_struct msg {
	nx_uint8_t msg_type;
	nx_uint16_t msg_counter;
	nx_uint16_t msg_value;
} msg_t;

enum{
AM_SEND_MSG = 6,
};

#endif
