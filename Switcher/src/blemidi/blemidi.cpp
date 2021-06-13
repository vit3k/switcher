#include "blemidi.h"
#include "utils.h"
// NOT used now
namespace Ble {

    void MidiBLECallbacks::onWrite(BLECharacteristic *pCharacteristic) {
      auto value = pCharacteristic->getValue();
      if (value.length() > 0) {
        Utils::printHex((byte*)value.data(), value.length());
        auto data = (uint8_t*)value.data();
        auto dataSize = value.length();
        bleParser.parseBLE(data, dataSize, receiver);
        pCharacteristic->setValue(nullptr, 0);
        pCharacteristic->notify();
      }
    }

    void Midi::setup(BLEServer* server, MidiMessageCallbackReceiver* receiver) {

        this->server = server;
        auto pService = server->createService(SERVICE_UUID);

        pCharacteristic = pService->createCharacteristic(
                                            CHARACTERISTIC_UUID,
                                            BLECharacteristic::PROPERTY_READ |
                                            BLECharacteristic::PROPERTY_WRITE_NR |
                                            BLECharacteristic::PROPERTY_WRITE |
                                            BLECharacteristic::PROPERTY_NOTIFY
                                            );
        pCharacteristic->setCallbacks(new MidiBLECallbacks(receiver));
        pCharacteristic->setAccessPermissions(ESP_GATT_PERM_READ_ENCRYPTED | ESP_GATT_PERM_WRITE_ENCRYPTED);

        uint8_t init[2] = {0x80, 0x80};
        pCharacteristic->setValue(init, 2);
        pService->start();
        server->getAdvertising()->addServiceUUID(SERVICE_UUID);
    }

    void Midi::send(uint8_t* data, uint8_t size)
    {
        if (size < 18)
        {
            uint8_t bleMsg[20] = {0x80, 0x80};
            memcpy(bleMsg + 2, data, size);
            pCharacteristic->setValue(bleMsg, size + 2);
            pCharacteristic->notify();
        }
        else
        {
            uint8_t bleMsg[20] = {0x80, 0x80};
            memcpy(bleMsg + 2, data, 18);
            pCharacteristic->setValue(bleMsg, 20);
            pCharacteristic->notify();
            auto current = 18;
            while(current < size) {
                auto sizeCorrected = min(18, (int)size - current);
                memcpy(bleMsg + 1, data + current, sizeCorrected);
                current += sizeCorrected;
                pCharacteristic->setValue(bleMsg, 19);
                pCharacteristic->notify();
            }
        }
    }
}