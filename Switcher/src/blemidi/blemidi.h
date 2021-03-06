#ifndef H_BLEMIDI
#define H_BLEMIDI

#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include "bleparser.h"

#define SERVICE_UUID        "03B80E5A-EDE8-4B33-A751-6CE34EC4C700"
#define CHARACTERISTIC_UUID "7772E5DB-3868-4112-A1A9-F2669D106BF3"

namespace Ble {
    using MidiMessageCallback = void(*)(uint8_t*, uint8_t);
    class Midi {
        private:
            BLECharacteristic* pCharacteristic;
            BLEServer* server;
        public:
            void setup(BLEServer* server, MidiMessageCallbackReceiver* receiver);
            void send(uint8_t* data, uint8_t size);
    };

    class MidiBLECallbacks: public BLECharacteristicCallbacks {
        MidiMessageCallbackReceiver* receiver;
        BLEParser bleParser;
        void onWrite(BLECharacteristic *pCharacteristic);
        public:
            MidiBLECallbacks(MidiMessageCallbackReceiver* receiver) {
                this->receiver = receiver;
            }
    };
}

#endif