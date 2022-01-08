#include <Arduino.h>
#include "utils.h"
#include <BLEDevice.h>
#include <BLEUtils.h>
#include <BLEServer.h>
#include <MIDI.h>
#include <Preferences.h>
#include "button.h"

#define CONFIGURATION_SERVICE_UUID "6DCEBA79-08CD-44F9-884A-CA34E76CA62C"
#define CONFIGURATION_PRESET_CHARACTERISTIC_UUID "441C54B6-9602-411F-BEB0-8044D443DFF8"
#define CONFIGURATION_CURRENT_PRESET_CHARACTERISTIC_UUID "441C54B6-9602-411F-BEB0-8044D443DFF9"

struct MidiCommand {
  uint8_t command;
  uint8_t data1;
  uint8_t data2;
  midi::MidiType getCommand() {
    return (midi::MidiType)(command & 0xF0);
  }
  midi::Channel getChannel() {
    return (command & 0x0F + 1);
  }
};

// presetId is 4 bits bank, 4 bits preset for example 00010001 (0x11) for bank 1 preset 1
struct Preset {
  uint8_t presetId;
  uint8_t loops;
  uint8_t switches;
  MidiCommand midiCommands[8];
  uint8_t clock; // 0 is disabled
  uint8_t getBank() {
    return (presetId & 0xF0) >> 4;
  }
  uint8_t getPreset() {
    return (presetId & 0x0F);
  }
  bool getLoop(uint8_t idx) {
    return (loops & (1 << idx)) != 0;
  }
  bool getSwitch(uint8_t idx) {
    return (switches & (1 << idx)) != 0;
  }
};

struct Bank {
  Preset presets[5];
};

void sendPreset();
void changePreset(Preset);
// MIDI (serial1):
// RX1 - 9
// TX1 - 10
/*struct MidiSettings : public midi::DefaultSettings
{
    static const long BaudRate = 115200;
};*/

//MIDI_CREATE_CUSTOM_INSTANCE(HardwareSerial, Serial, MIDI, MidiSettings);
MIDI_CREATE_CUSTOM_INSTANCE(HardwareSerial, Serial1, MIDI, midi::DefaultSettings);
// relays (possible switch to shift register 74HC595 then only 3 pins will be used):
// 13, 12, 24, 14, 27, 26, 25, 33
#define RELAY_NUMBER 8
uint8_t relays[] = {13, 12, 24, 14, 27, 26, 25, 33};
#define SWITCH_NUMBER 1
uint8_t switches[] = {16};
// leds:
// 23, 22, 21, 19, 18
#define LED_NUMBER 4
uint8_t leds[] = {23, 22, 21, 19, 18};
// left:
// 17, 15, 2, 4, 5
Button buttons[5] = {Button(36), Button(39), Button(34), Button(35), Button(32)/*, Button(26)*/};
MultiButton bankUpButton(&buttons[0], &buttons[1]);
MultiButton bankDownButton(&buttons[1], &buttons[2]);

Preset preset = {0x11, 0x01, 0x00};
Bank banks[5];
int currentBank = 0;
int currentPreset = 0;
unsigned long lastClockTime;
unsigned int channel = 0;

Preferences preferences;



BLEServer* server;
BLECharacteristic* characteristic;
BLECharacteristic* currentPresetCharacteristic;
BLEService* service;

class ServerCallback: public BLEServerCallbacks {
  virtual void onConnect(BLEServer* pServer)
  {
    Serial.println("Connected");
  }

	virtual void onDisconnect(BLEServer* pServer)
  {
    Serial.println("Disconnected");
    pServer->startAdvertising();
  }
};

class PresetCharacteristicCallback: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      auto value = pCharacteristic->getValue();
      if (value.length() > 0) {
        Utils::printHex((byte*)value.data(), value.length());

        auto preset = (Preset*)value.data();
        banks[preset->getBank()].presets[preset->getPreset()] = *preset;
        char id[4];
        sprintf(id, "%d.%d", preset->getBank(), preset->getPreset());
        Serial.printf("Saving %s\n", id);
        preferences.putBytes(id, preset, sizeof(Preset));
      }
    };
};

class CurrentPresetCharacteristicCallback: public BLECharacteristicCallbacks {
    void onWrite(BLECharacteristic *pCharacteristic) {
      auto value = pCharacteristic->getValue();
      if (value.length() > 0) {
        Utils::printHex((byte*)value.data(), value.length());
        auto presetId = (byte)*value.data();
        Serial.printf("%d\n", presetId);
        auto bank = (presetId >> 4);
        auto presetNumber = (presetId & 0x0F);
        auto preset = banks[bank].presets[presetNumber];
        changePreset(preset);
      }
    };
};

uint8_t clamp(int8_t value, int8_t delta, int8_t min, int8_t max)
{
    auto newValue = value + delta;
    if (newValue < min)
    {
        newValue = max;
    }
    if (newValue > max)
    {
        newValue = min;
    }
    return newValue;
}

void setup() {
  Serial.begin(115200);
  preferences.begin("config");
  //preferences.clear();
  channel = preferences.getUChar("channel", 0x00);
  auto presetId = preferences.getUChar("lastPresetId", 0x00);
  currentBank = presetId >> 4;
  currentPreset = presetId & 0x0F;

  for(auto i = 0; i < 5; i++) {
    for (auto j = 0; j < 5; j++) {
      Preset preset;
      preset.presetId = (i << 4) | j;
      char id[4];
      sprintf(id, "%d.%d", i, j);
      if (preferences.isKey(id)) {
        Serial.printf("Found preset %s\n", id);
        preferences.getBytes(id, &preset, sizeof(Preset));
        Utils::printHex((uint8_t*)&preset, sizeof(Preset));
        banks[i].presets[j] = preset;
      } else {
        preferences.putBytes(id, &preset, sizeof(Preset));
      }
    }
  }

  BLEDevice::init("Switcher");
  BLEDevice::setEncryptionLevel((esp_ble_sec_act_t)ESP_LE_AUTH_REQ_SC_BOND);

  server = BLEDevice::createServer();
  server->setCallbacks(new ServerCallback());

  service = server->createService(CONFIGURATION_SERVICE_UUID);

  characteristic = service->createCharacteristic(
                                      CONFIGURATION_PRESET_CHARACTERISTIC_UUID,
                                      BLECharacteristic::PROPERTY_READ |
                                      BLECharacteristic::PROPERTY_WRITE |
                                      BLECharacteristic::PROPERTY_NOTIFY
                                      );

  characteristic->setCallbacks(new PresetCharacteristicCallback());
  characteristic->setAccessPermissions(ESP_GATT_PERM_READ_ENCRYPTED | ESP_GATT_PERM_WRITE_ENCRYPTED);

  currentPresetCharacteristic = service->createCharacteristic(
                                      CONFIGURATION_CURRENT_PRESET_CHARACTERISTIC_UUID,
                                      BLECharacteristic::PROPERTY_READ |
                                      BLECharacteristic::PROPERTY_WRITE |
                                      BLECharacteristic::PROPERTY_NOTIFY
                                      );

  currentPresetCharacteristic->setCallbacks(new CurrentPresetCharacteristicCallback());
  currentPresetCharacteristic->setAccessPermissions(ESP_GATT_PERM_READ_ENCRYPTED | ESP_GATT_PERM_WRITE_ENCRYPTED);

  
  service->start();
  
  sendPreset();
  
  auto pSecurity = new BLESecurity();
  pSecurity->setAuthenticationMode(ESP_LE_AUTH_REQ_SC_BOND);
  pSecurity->setCapability(ESP_IO_CAP_NONE);
  pSecurity->setInitEncryptionKey(ESP_BLE_ENC_KEY_MASK | ESP_BLE_ID_KEY_MASK);

  server->getAdvertising()->addServiceUUID(CONFIGURATION_SERVICE_UUID);

  server->getAdvertising()->start();

  for(auto i = 0; i < RELAY_NUMBER; i++) {
    pinMode(relays[i], OUTPUT);  
  }
  for(auto i = 0; i < SWITCH_NUMBER; i++) {
    pinMode(switches[i], OUTPUT);  
  }
  for(auto i = 0; i < LED_NUMBER; i++) {
    pinMode(leds[i], OUTPUT);  
  }
  MIDI.begin();
  lastClockTime = micros();
  Serial.println("Setup completed");
}

void changePreset(Preset preset) {
  currentPreset = preset.getPreset();
  currentBank = preset.getBank();
  Serial.printf("%d %d\n", currentBank, currentPreset);
  // 1. set loops outputs
  for(auto i = 0; i < RELAY_NUMBER; i++) {
    digitalWrite(relays[i], preset.getLoop(i) ? HIGH : LOW);
  }
  // 2. set switches
  for(auto i = 0; i < SWITCH_NUMBER; i++) {
    digitalWrite(switches[i], preset.getSwitch(i) ? HIGH : LOW);
  }
  // 3. send midi messages
  for(auto i = 0; i < 8; i++) {
    auto midiCmd = preset.midiCommands[i];
    if (midiCmd.command != 0) {
      switch(midiCmd.getCommand()) {
        case midi::MidiType::ProgramChange: 
          MIDI.send(midiCmd.getCommand(), midiCmd.data1, 0, midiCmd.getChannel());
          break;
        case midi::MidiType::ControlChange:
          MIDI.send(midiCmd.getCommand(), midiCmd.data1, midiCmd.data2, midiCmd.getChannel());
          break;
        default:
          break;
      }
      
    }
  }
  // 4. update leds??
  for(auto i = 0; i < LED_NUMBER; i++) {
    // clear all leds
    digitalWrite(leds[i], LOW);
    //digitalWrite(leds[i], preset.getPreset() == i ? HIGH : LOW);
  }
  digitalWrite(leds[preset.getPreset()], HIGH);

  // 5. send current preset data by bluetooth to app
  sendPreset();
  // 6. save current bank and preset to preferences
  auto presetId = (uint8_t)((currentBank << 4) | currentPreset); 
  preferences.putUChar("lastPresetId", presetId);
}

void sendPreset()
{
  Utils::printHex((uint8_t*)&banks[currentBank].presets[currentPreset], sizeof(Preset));
  
  characteristic->setValue((uint8_t*)&banks[currentBank].presets[currentPreset], sizeof(Preset));
  characteristic->notify();

  currentPresetCharacteristic->setValue(&banks[currentBank].presets[currentPreset].presetId, sizeof(uint8_t));
  currentPresetCharacteristic->notify();
}

void nextBank()
{
  currentBank++;
  if (currentBank >= 5) {
    currentBank = 0;
  }
  changePreset(banks[currentPreset].presets[currentPreset]);
}

void prevBank()
{
  currentBank--;
  if (currentBank < 0) {
    currentBank = 4;
  }
  changePreset(banks[currentPreset].presets[currentPreset]);
}

void updateButtons()
{
    for (auto btnIdx = 0; btnIdx < 5; btnIdx++)
    {
        buttons[btnIdx].update();
    }
    bankUpButton.update();
    bankDownButton.update();
}


void loop() {
  // change preset on MIDI input
  if (MIDI.read()) {
    if (MIDI.getChannel() == 0 && MIDI.getType() == midi::ProgramChange) {
      auto midiPreset = MIDI.getData1();
      auto bankNumber = midiPreset / 5;
      auto presetNumber = midiPreset % 5;

      changePreset(banks[bankNumber].presets[presetNumber]);
    }
  }

  updateButtons();
  if (bankUpButton.pressed()) {
    nextBank();
  }
  if (bankDownButton.pressed()) {
    prevBank();
  }

  for (auto btnIdx = 0; btnIdx < 5; btnIdx++)
  {
      if (buttons[btnIdx].pressed()) {
        changePreset(banks[currentBank].presets[btnIdx]);
      }
  }
  /*auto preset = banks[currentBank].presets[currentPreset];
  if (preset.clock != 0) {
    // TODO: clock implementation  
    // 24 times per quarter note
    unsigned int clockPulseUs = 600000 / (preset.clock * 24);
    auto currentUs = micros();
    auto delta = currentUs - lastClockTime;
    if (delta < 0) {
      delta = ULONG_MAX - lastClockTime + currentUs;
    }
    if ( delta >= clockPulseUs) {
      MIDI.sendClock();
      lastClockTime = currentUs;
    }
  }*/
    
}

