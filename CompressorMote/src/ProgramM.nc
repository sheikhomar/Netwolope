#include <UserButton.h>
#include "printf.h"

module ProgramM {
  uses {
    interface Boot;
    interface Leds;
    interface PCFileReceiver;
    interface OnlineCompressionAlgorithm as Compressor;
    interface RadioSender;
    interface ErrorIndicator;
    interface FlashReader;
    interface FlashWriter;
    interface FlashError;
    interface CircularBufferReader as UncompressedBufferReader;
    interface CircularBufferWriter as UncompressedBufferWriter;
    interface Notify<button_state_t> as Button;
  }
}
implementation {
  uint16_t _imageWidth;
  uint8_t ready = 0;
  uint16_t i;

  uint8_t mock[1040] = {
    0x50, 0x35, 0x0a, 0x23, 0x2a, 0x0a, 0x33, 0x32, 0x20, 0x33, 0x32, 0x0a,
    0x32, 0x35, 0x35, 0x0a, 0xf7, 0xff, 0xd2, 0xc7, 0xff, 0xfd, 0xff, 0xff,
    0xfc, 0xf8, 0xf9, 0xf8, 0xf6, 0xff, 0xfd, 0xff, 0xda, 0x67, 0x63, 0xda,
    0xff, 0xfb, 0x9c, 0xf1, 0xff, 0xfa, 0xff, 0x88, 0x98, 0xff, 0xfd, 0xfe,
    0x72, 0xbc, 0x9a, 0x57, 0x8f, 0x77, 0xbc, 0x67, 0x57, 0x59, 0x47, 0x6c,
    0x73, 0xbc, 0x8b, 0xff, 0x97, 0x40, 0x3d, 0x74, 0xdc, 0x7d, 0x26, 0x57,
    0x7a, 0x5b, 0x65, 0x39, 0x36, 0x64, 0xbb, 0xec, 0x62, 0x38, 0x3d, 0x4e,
    0x3f, 0x25, 0x4f, 0x3c, 0xdd, 0x46, 0xa3, 0xfd, 0x53, 0x21, 0xaa, 0xff,
    0xb0, 0x35, 0x5b, 0x44, 0x46, 0x52, 0x48, 0xb6, 0x5e, 0x27, 0x45, 0x6d,
    0x7e, 0x6c, 0x45, 0x54, 0x5e, 0x75, 0x74, 0x66, 0x61, 0x1a, 0x37, 0x3d,
    0xf1, 0x6e, 0xb7, 0xe0, 0x34, 0x8c, 0xff, 0xff, 0xb5, 0x5f, 0xd2, 0x3b,
    0x4d, 0x6e, 0x54, 0xff, 0x8b, 0x18, 0x34, 0x46, 0x81, 0x6e, 0x4a, 0x3d,
    0x5d, 0xa1, 0xec, 0xcc, 0xd5, 0x8f, 0xb8, 0xc0, 0xed, 0xfb, 0xc8, 0x40,
    0xa2, 0xff, 0xfc, 0xff, 0xf0, 0xd2, 0xff, 0xb3, 0x9d, 0xec, 0xd2, 0xff,
    0xec, 0xa2, 0xc0, 0xb2, 0xba, 0xf0, 0x99, 0xd5, 0xe6, 0xee, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfd, 0xfb, 0xff, 0xfb, 0xfc, 0xfd,
    0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xfd, 0xfd, 0xfb, 0xfc, 0xfc,
    0xff, 0xfe, 0xfd, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfd, 0xfe, 0xfc,
    0xfc, 0xfe, 0xfd, 0xff, 0xfe, 0xfc, 0xfc, 0xfd, 0xfd, 0xfe, 0xfb, 0xfd,
    0xfe, 0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfd, 0xff, 0xea,
    0xc9, 0xb6, 0xb2, 0xbf, 0xdc, 0xfb, 0xff, 0xfe, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xf8, 0xad, 0x92, 0x8a, 0x98, 0xa8, 0x9f,
    0x94, 0x98, 0xe3, 0xff, 0xfe, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xfc, 0x9d, 0xa2, 0xbb, 0xa0, 0xb3, 0xb7, 0xb8, 0xbc, 0xad, 0x8d, 0xef,
    0xff, 0xfe, 0xff, 0xff, 0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfd, 0xff, 0xb2, 0x95, 0x80, 0x98,
    0xba, 0xb5, 0xb7, 0xb5, 0xac, 0x6d, 0x68, 0xb3, 0xff, 0xfd, 0xff, 0xff,
    0xfb, 0xdf, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xfe, 0xff, 0xeb, 0x93, 0x9e, 0x38, 0x98, 0xba, 0xaa, 0xa0, 0xb1,
    0xb3, 0x5c, 0x83, 0x94, 0xe8, 0xff, 0xfc, 0xff, 0xc3, 0x8a, 0xff, 0xfc,
    0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfd, 0xff, 0xc5,
    0xa2, 0xa0, 0x8b, 0xad, 0xb6, 0x9d, 0x84, 0xac, 0xb5, 0x9b, 0x97, 0x9b,
    0xc1, 0xff, 0xfc, 0xff, 0x80, 0xe0, 0xff, 0xf9, 0xf4, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfd, 0x76, 0x96, 0xb3, 0xae, 0xb9,
    0xba, 0xbd, 0xbe, 0xba, 0xbb, 0xb4, 0xb7, 0xa5, 0x98, 0xff, 0xff, 0xbf,
    0x73, 0xe5, 0xa6, 0x78, 0x91, 0xff, 0xfe, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xfc, 0xff, 0xa1, 0x6f, 0x3d, 0x4e, 0x76, 0x8c, 0x93, 0x91, 0x9c, 0x9a,
    0x92, 0x93, 0x78, 0x57, 0x30, 0xdf, 0xff, 0x7d, 0x8c, 0x92, 0xa2, 0xcf,
    0xf1, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfc, 0xff, 0x91, 0x76,
    0x21, 0x78, 0xa0, 0x21, 0x4a, 0x7c, 0x2c, 0x4c, 0x77, 0x1e, 0x5c, 0xc4,
    0x2f, 0xc3, 0xc8, 0x95, 0xff, 0xff, 0xb4, 0x84, 0xfb, 0xd3, 0xf2, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xfc, 0xff, 0xb5, 0x40, 0x1f, 0x8b, 0xa8, 0x1d,
    0x89, 0xc8, 0x1f, 0x69, 0xd3, 0x2c, 0x45, 0xaf, 0x42, 0x75, 0x49, 0xc2,
    0xff, 0xbd, 0xa7, 0xa6, 0xa3, 0x9d, 0xdb, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xfd, 0xff, 0xa8, 0xab, 0x91, 0x70, 0x60, 0x37, 0x5a, 0x6c, 0x2c, 0x4a,
    0x6d, 0x44, 0x5b, 0x4d, 0x96, 0x9d, 0x5e, 0xc8, 0xff, 0xd2, 0xbb, 0xe2,
    0xf6, 0xfc, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfd, 0x9a, 0xb3,
    0xbb, 0xbb, 0xb4, 0xb1, 0xa1, 0x9a, 0xa4, 0xab, 0x63, 0x86, 0xa6, 0x5e,
    0x9c, 0x98, 0xd6, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfd, 0xfe, 0xff,
    0xff, 0xff, 0xff, 0xfe, 0xff, 0xf1, 0x95, 0xb6, 0xb1, 0xb2, 0xb3, 0xb4,
    0xb8, 0xb9, 0xb5, 0xbe, 0x92, 0x1f, 0x1c, 0x37, 0x8c, 0xe4, 0xff, 0xfd,
    0xff, 0xfe, 0xfd, 0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe,
    0xff, 0xe4, 0x95, 0xb9, 0xb2, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb1, 0xb9,
    0x94, 0x54, 0x85, 0x5d, 0x86, 0xe9, 0xff, 0xfe, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfd, 0xff, 0xd9, 0x97, 0xb9,
    0xb2, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb2, 0xba, 0x99, 0x6d, 0xc5, 0x70,
    0x82, 0xf0, 0xff, 0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xfd, 0xff, 0xd6, 0x98, 0xb9, 0xb2, 0xb3, 0xb3, 0xb3,
    0xb3, 0xb3, 0xb3, 0xb6, 0xaa, 0x2c, 0x1c, 0x37, 0x8e, 0xf4, 0xff, 0xfe,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe,
    0xff, 0xdc, 0x97, 0xb9, 0xb2, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb8,
    0xa0, 0x59, 0x72, 0x49, 0x8e, 0xfa, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xff, 0xe7, 0x95, 0xb8,
    0xb2, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb2, 0xba, 0x98, 0x5b, 0x8f, 0x5b,
    0x98, 0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xfb, 0x97, 0xb4, 0xb3, 0xb3, 0xb3, 0xb3,
    0xb3, 0xb3, 0xb3, 0xb6, 0xa5, 0x49, 0x34, 0x5b, 0xa4, 0xff, 0xfe, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xfd, 0xff, 0xb3, 0xa0, 0xb8, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3,
    0xb6, 0x98, 0x94, 0x98, 0xb7, 0xff, 0xfd, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfe, 0xff, 0xec, 0x8d,
    0xb8, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb3, 0xb6, 0xc0, 0x91,
    0xe1, 0xff, 0xfe, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xfd, 0xff, 0xc5, 0x8e, 0xbc, 0xb5, 0xb2,
    0xb3, 0xb3, 0xb3, 0xb2, 0xb4, 0xbd, 0x97, 0xac, 0xff, 0xfe, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xfe, 0xff, 0xbb, 0x8c, 0xaf, 0xb9, 0xb9, 0xb8, 0xb9, 0xb8,
    0xaf, 0x91, 0xa5, 0xfb, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfd,
    0xff, 0xd7, 0x9c, 0x96, 0x9b, 0x9e, 0x9b, 0x96, 0x9e, 0xcd, 0xff, 0xfe,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xfd, 0xff, 0xfd, 0xe4,
    0xcc, 0xc4, 0xca, 0xe6, 0xfe, 0xff, 0xfd, 0xff, 0xff, 0xff, 0xff, 0xff,
    0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff
  };
  
  event void Boot.booted(){
    for (i = 0; i < 1040; i++)
      call UncompressedBufferWriter.write(mock[i]);
    
    call Button.enable();
    call FlashReader.prepareRead();
    /*call PCFileReceiver.init();*/
  }

  event void Button.notify(button_state_t state) {
    if (state == BUTTON_PRESSED && ready) {
      printf("Starting compression...\n");
      call Compressor.fileBegin(_imageWidth);
      call FlashReader.readNextChunk();
      ready = 0;
    }
    /*printfflush();*/
  }
  
  event void PCFileReceiver.initDone(){ 
     call Leds.set(0);
     call Leds.led1On();
  }
  
  event void PCFileReceiver.fileBegin(uint16_t width){
    call FlashWriter.prepareWrite(width);
  }
    
  event void FlashWriter.readyToWrite(){
    call Leds.led1Toggle();
    call PCFileReceiver.sendFileBeginAck();
  }
  
  event void PCFileReceiver.receivedData(){
    call FlashWriter.writeNextChunk();
  }

  event void FlashWriter.chunkWritten(){
    call Leds.led1Toggle();
    call PCFileReceiver.receiveMore();
  }
  
  event void PCFileReceiver.fileEnd(){
    call FlashReader.prepareRead();
  }
  
  event void FlashReader.readyToRead(uint16_t width){
    _imageWidth = width;
    call RadioSender.init();
  }
  
  event void RadioSender.initDone(){ 
    call RadioSender.sendFileBegin(_imageWidth, call Compressor.getCompressionType());
  }
  
  event void RadioSender.fileBeginAcknowledged(){ 
    /*call Compressor.fileBegin(_imageWidth);
    call FlashReader.readNextChunk();*/
    ready = 1;
  }

  event void FlashReader.chunkRead(){
    call Compressor.compress(call FlashReader.isFinished());
  }
  
  event void Compressor.compressed(){
    call RadioSender.sendPartialData();
  }

  event void RadioSender.sendDone(){
    if (call RadioSender.canSend()) {
      call RadioSender.sendPartialData();
      
    } else if (call FlashReader.isFinished()) {
      call RadioSender.sendEOF();
      call Leds.led2On();
      
    } else {
      call FlashReader.readNextChunk();
    }
  }  
  
  event void PCFileReceiver.error(PCFileReceiverError error){
    call ErrorIndicator.blinkRed(error);
  }

  event void RadioSender.error(RadioSenderError error){
    call ErrorIndicator.blinkRed(error);
  }

  event void FlashError.onError(error_t error){
    call ErrorIndicator.blinkRed(2);
  }

  event void Compressor.error(CompressionError error){
    call ErrorIndicator.blinkRed(3);
  }
}
