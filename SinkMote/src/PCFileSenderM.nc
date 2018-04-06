
#include "AM.h"
#include "Serial.h"
#include "PCFileSender.h"

module PCFileSenderM{
  provides {
    interface PCFileSender;
  }

  uses {
    interface Timer<TMilli> as Timeout;
    
    interface SplitControl as SerialControl;
    interface Packet as SerialPacket;
    interface AMPacket as SerialAMPacket;
    interface AMSend as SerialSend[am_id_t msg_type];
    interface Receive as SerialReceive[am_id_t msg_type];
  }
}
implementation{
  typedef enum {
    STATE_BEGIN,
    STATE_SENDING_START_REQUEST,
    STATE_WAITING_START_RESPONSE,
    STATE_ESTABLISHED,
    STATE_SENDING_PARTIAL_DATA
  } ConnectionState;
  
  enum {
    AM_TRANSMIT_BEGIN_MSG = 0x40,
    AM_TRANSMIT_BEGIN_ACK_MSG = 0x41,
    AM_PARTIAL_DATA_MSG = 0x42,
    AM_TRANSMIT_END_MSG = 0x43
  };

  typedef nx_struct TransmitBeginMsg {
    nx_uint8_t bufferSize;
  } TransmitBeginMsg;

  typedef nx_struct PartialDataMsg {
    nx_uint8_t size;
    nx_uint8_t data[49];
  } PartialDataMsg;

  typedef nx_struct {
    nx_uint8_t temp;
  } EndOfFileMsg;
  
  message_t packet;
  uint8_t currentRetry = 0;
  ConnectionState state = STATE_BEGIN;
  
  TransmitBeginMsg* prepareTransmitBeginMsg() {
    TransmitBeginMsg* msg = (TransmitBeginMsg*)call SerialPacket.getPayload(&packet, sizeof(TransmitBeginMsg));
    if (msg == NULL) {
      signal PCFileSender.error(PC_CONN_UNEXPECTED_ERROR);
    }
    if (call SerialPacket.maxPayloadLength() < sizeof(TransmitBeginMsg)) {
      signal PCFileSender.error(PC_CONN_UNEXPECTED_ERROR);
    }
    return msg;
  }
  
  PartialDataMsg* preparePartialDataMsg() {
    PartialDataMsg* msg = (PartialDataMsg*)call SerialPacket.getPayload(&packet, sizeof(PartialDataMsg));
    if (msg == NULL) {
      signal PCFileSender.error(PC_CONN_UNEXPECTED_ERROR);
    }
    if (call SerialPacket.maxPayloadLength() < sizeof(PartialDataMsg)) {
      signal PCFileSender.error(PC_CONN_UNEXPECTED_ERROR);
    }
    return msg;
  }
  
  EndOfFileMsg* prepareEndOfFileMsg() {
    EndOfFileMsg* msg = (EndOfFileMsg*)call SerialPacket.getPayload(&packet, sizeof(EndOfFileMsg));
    if (msg == NULL) {
      signal PCFileSender.error(PC_CONN_UNEXPECTED_ERROR);
    }
    if (call SerialPacket.maxPayloadLength() < sizeof(EndOfFileMsg)) {
      signal PCFileSender.error(PC_CONN_UNEXPECTED_ERROR);
    }
    return msg;
  }
  
  void sendPartialData(uint8_t *data, uint8_t size) {
    PartialDataMsg* msg = preparePartialDataMsg();
    uint8_t i;
    
    msg->size = size;
    for (i = 0; i < size; i++) {
      msg->data[i] = data[i];
    }
    
    if (call SerialSend.send[AM_PARTIAL_DATA_MSG](AM_BROADCAST_ADDR, &packet, sizeof(PartialDataMsg)) == SUCCESS) {
      atomic {
        state = STATE_SENDING_PARTIAL_DATA;
      }
    } else {
      signal PCFileSender.error(PC_CONN_ERR_DISCONNECTED);
    }
  }
  
  void sendPartialDataMessage(message_t *msg, uint8_t msgSize) {
    if (call SerialSend.send[AM_PARTIAL_DATA_MSG](AM_BROADCAST_ADDR, msg, msgSize) == SUCCESS) {
      atomic {
        state = STATE_SENDING_PARTIAL_DATA;
      }
    } else {
      signal PCFileSender.error(PC_CONN_ERR_DISCONNECTED);
    }
    
  }
  
  void sendEOFMessage() {
    EndOfFileMsg* msg = prepareEndOfFileMsg();
    msg->temp = 1; // TODO: Fix this by sending something meaningful
    
    if (call SerialSend.send[AM_TRANSMIT_END_MSG](AM_BROADCAST_ADDR, &packet, sizeof(EndOfFileMsg)) == SUCCESS) {
      atomic {
        state = STATE_SENDING_PARTIAL_DATA;
      }
    } else {
      signal PCFileSender.error(PC_CONN_ERR_DISCONNECTED);
    }
  }
  
  task void sendTransmitBeginMsg() {
    TransmitBeginMsg* msg = prepareTransmitBeginMsg();
    msg->bufferSize = 53; // TODO: Fix this by sending something meaningful
    
    if (call SerialSend.send[AM_TRANSMIT_BEGIN_MSG](AM_BROADCAST_ADDR, &packet, sizeof(TransmitBeginMsg)) == SUCCESS) {
      atomic {
        state = STATE_SENDING_START_REQUEST;
      }
    } else {
      post sendTransmitBeginMsg();
    }
  }
  
  task void startCommunicationTask() {
    atomic {
        currentRetry += 1;
    }
    post sendTransmitBeginMsg();
  }

  command void PCFileSender.init(){
    call SerialControl.start();
  }
  
  /* REGION: Event handlers */

  event void SerialControl.startDone(error_t error){
    if (error == SUCCESS) {
      post startCommunicationTask();
    } else {
      signal PCFileSender.error(PC_CONN_UNEXPECTED_ERROR);
    }
  }

  event void SerialControl.stopDone(error_t error){ }

  event void Timeout.fired(){
    atomic {
      if (state == STATE_WAITING_START_RESPONSE) {
        // Timeout reach and we are still waiting for
        // a response from PC. Retry once more.
        post startCommunicationTask();
      }
    }
  }

  event void SerialSend.sendDone[am_id_t msg_type](message_t *msg, error_t error){
    if (error == SUCCESS) {
      atomic {
        if (state == STATE_SENDING_START_REQUEST) {
          // BeginTransmit Message has been sent to the PC
          // Now we are waiting for a response.
          state = STATE_WAITING_START_RESPONSE;
          
          // Wait 2 seconds before resending the
          // BeginTransmit message to the PC.
          call Timeout.startOneShot(2000);
          
        } else if (state == STATE_SENDING_PARTIAL_DATA) {
          // The data that we have sent the PC was
          // received successfully. We go back to a
          // previous state where client can send 
          // more data.
          state = STATE_ESTABLISHED;
          
          // Signal client that the SEND request
          // was fulfilled.
          signal PCFileSender.sent();
        }
      }
    } else {
      signal PCFileSender.error(PC_CONN_UNEXPECTED_ERROR);
    }
  }

  event message_t * SerialReceive.receive[am_id_t msg_type](message_t *msg, void *payload, uint8_t len){
    atomic {
      if (state == STATE_WAITING_START_RESPONSE) {
        
        if (msg_type == AM_TRANSMIT_BEGIN_ACK_MSG) {
          // We have received an ACK for the TransmitBegin message.
          // This means that we have established a connection to 
          // the PC.
          call Timeout.stop();
          
          state = STATE_ESTABLISHED;
          signal PCFileSender.established();
        }
      }
    }
    return msg;
  }

  command void PCFileSender.send(uint8_t *data, uint8_t size){
    atomic {
      if (state == STATE_ESTABLISHED) {
        sendPartialData(data, size);
      } else {
        signal PCFileSender.error(PC_CONN_NOT_CONNECTED);
      }
    }
  }

  command void PCFileSender.sendMessage(message_t *message, uint8_t payloadSize){
    atomic {
      if (state == STATE_ESTABLISHED) {
        sendPartialDataMessage(message, payloadSize);
      } else {
        signal PCFileSender.error(PC_CONN_NOT_CONNECTED);
      }
    }
  }

  command void PCFileSender.sendEOF(){
    atomic {
      if (state == STATE_ESTABLISHED) {
        sendEOFMessage();
      } else {
        signal PCFileSender.error(PC_CONN_NOT_CONNECTED);
      }
    }
  }
}