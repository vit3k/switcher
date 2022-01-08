//
//  ble.swift
//  testble2
//
//  Created by Pawel Witkowski on 05/06/2021.
//

import CoreBluetooth

enum MidiCommandType: CustomStringConvertible {
    var description: String {
        switch(self) {
        case .Empty: return "Empty"
        case .ProgramChange: return "Program Change"
        case .ControlChange: return "Control Change"
        }
    }
    
    
    case Empty, ProgramChange, ControlChange
}
struct MidiCommand: Identifiable, Equatable {
    var id = UUID()
    
    var channel: Int = 0
    var command: MidiCommandType = MidiCommandType.Empty
    var data1: Int = 0
    var data2: Int = 0
}
struct Preset: Equatable {
    
    var bank: Int = 0
    var preset: Int = 0
    var loops = [Bool](repeating: false, count: 8)
    var switch1: Bool = false
    var midiCommands = [MidiCommand](repeating: MidiCommand(), count: 8)
    var clock: Int = 0
}

class BLE: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate, ObservableObject {
    let configurationServiceUUID = CBUUID(string: "6DCEBA79-08CD-44F9-884A-CA34E76CA62C")
    let presetDataCharacteristicUUID = CBUUID(string: "441C54B6-9602-411F-BEB0-8044D443DFF8")
    let currentPresetCharacteristicUUID = CBUUID(string: "441C54B6-9602-411F-BEB0-8044D443DFF9")
    
    init(isConnected: Bool) {
        super.init()
        self.isConnected = isConnected
    }
    var centralManager: CBCentralManager! = nil
    var peripheral: CBPeripheral! = nil
    var configurationService: CBService! = nil
    var presetDataCharacteristic: CBCharacteristic! = nil
    var currentPresetCharacteristic: CBCharacteristic! = nil

    @Published var devices: [CBPeripheral] = []
    @Published var isScanning: Bool = false
    @Published var isConnected: Bool = false
    @Published var preset = Preset()
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
          case .unknown:
            print("central.state is .unknown")
          case .resetting:
            print("central.state is .resetting")
          case .unsupported:
            print("central.state is .unsupported")
          case .unauthorized:
            print("central.state is .unauthorized")
          case .poweredOff:
            print("central.state is .poweredOff")
          case .poweredOn:
            print("central.state is .poweredOn")
            checkConnected()
            //scan()
        @unknown default:
            print("central.state is unknown")
        }
    }
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    func checkConnected() {
        var found = false
        let connected = centralManager.retrieveConnectedPeripherals(withServices: [configurationServiceUUID])
        for device in connected {
            if device.identifier.uuidString == UserDefaults.standard.string(forKey: "lastdevice") {
                print(device)
                self.peripheral = device
                self.peripheral.delegate = self
                connect(device: device)
                found = true
                break
            }
        }
        if !found {
            scan()
        }
    }
    
    func scan() {
        devices.removeAll()
        isScanning = true
        centralManager.scanForPeripherals(withServices: [configurationServiceUUID])
    }
    func stopScan() {
        isScanning = false
        centralManager.stopScan()
    }
    func connect(device: CBPeripheral) {
        stopScan()
        centralManager.connect(device)
        UserDefaults.standard.set(device.identifier.uuidString, forKey: "lastdevice")
        
    }
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !devices.contains(peripheral) {
            print(peripheral)
            devices.append(peripheral)
            if peripheral.identifier.uuidString == UserDefaults.standard.string(forKey: "lastdevice") {
                print("found known device. Connecting \(peripheral.name ?? peripheral.identifier.uuidString)")
                connect(device: peripheral)
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        isConnected = true
        print("Connected \(peripheral.name ?? peripheral.identifier.uuidString)")
        peripheral.delegate = self
        self.peripheral = peripheral
        peripheral.discoverServices(nil)
        
        print(peripheral.maximumWriteValueLength(for: CBCharacteristicWriteType.withResponse))
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected \(peripheral.name ?? peripheral.identifier.uuidString)")
        self.peripheral = nil
        presetDataCharacteristic = nil
        configurationService = nil
        isConnected = false
        scan()
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        //print(peripheral.services)
        if let services = peripheral.services {
            
            for service in services {
                print(service.uuid)
                if service.uuid == configurationServiceUUID {
                    print("Found configuration service")
                    self.configurationService = service
                    peripheral.discoverCharacteristics([presetDataCharacteristicUUID, currentPresetCharacteristicUUID], for: service)
                }
            }
        }
       
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let chars = service.characteristics {
            for char in chars {
                if char.uuid == presetDataCharacteristicUUID {
                    print("Found preset data characteristic")
                    self.presetDataCharacteristic = char
                    peripheral.readValue(for: char)
                    peripheral.setNotifyValue(true, for: char)
                }
                if char.uuid == currentPresetCharacteristicUUID {
                    print("Found current preset characteristic")
                    self.currentPresetCharacteristic = char
                    peripheral.readValue(for: char)
                    peripheral.setNotifyValue(true, for: char)
                }
            }
        }
    }
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        /*if characteristic.uuid == presetDataCharacteristicUUID {
            let array = [UInt8](characteristic.value!)
            print(array)
        }*/
    }
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == presetDataCharacteristicUUID {
            let array = [UInt8](characteristic.value!)
            print("from ble: \(array)")
            var newPreset = Preset(
                bank: Int(array[0] >> 4),
                preset: Int(array[0] & 0x0F),
                loops: [array[1] & 0b00000001 != 0,
                        array[1] & 0b00000010 != 0,
                        array[1] & 0b00000100 != 0,
                        array[1] & 0b00001000 != 0,
                        array[1] & 0b00010000 != 0,
                        array[1] & 0b00100000 != 0,
                        array[1] & 0b01000000 != 0,
                        array[1] & 0b10000000 != 0],
                switch1: array[2] & 0b00000001 != 0
            )
            for i in 0...7 {
                newPreset.midiCommands[i].channel = Int(array[3 + i * 3] & 0x0F) + 1
                let command = Int(array[3 + i * 3] >> 4)
                switch(command) {
                case 0b1011:
                    newPreset.midiCommands[i].command = MidiCommandType.ControlChange
                    break
                case 0b1100:
                    newPreset.midiCommands[i].command = MidiCommandType.ProgramChange
                    break
                default:
                    newPreset.midiCommands[i].command = MidiCommandType.Empty
                    break
                }
                newPreset.midiCommands[i].data1 = Int(array[3 + i * 3 + 1])
                newPreset.midiCommands[i].data2 = Int(array[3 + i * 3 + 2])
            }
            newPreset.clock = Int(array[27])
            preset = newPreset
            print(preset)
        }
        if characteristic.uuid == currentPresetCharacteristicUUID {
            
        }
    }
    
    func update() {
        if peripheral == nil {
            print("Not connected")
            return
        }
        var array = [UInt8]()
        array.append(UInt8(preset.bank << 4 | preset.preset))
        var loops: UInt8 = 0
        for i in 0...7 {
            loops = loops | ((preset.loops[i] == true ? 1 : 0) << i)
        }
        array.append(loops)
        array.append(UInt8(preset.switch1 ? 1 : 0))
        
        for i in 0...7 {
            var command: UInt8 = UInt8(preset.midiCommands[i].channel) - 1
            switch(preset.midiCommands[i].command) {
            case MidiCommandType.ControlChange:
                command = command | 0b10110000
                break
            case MidiCommandType.ProgramChange:
                command = command | 0b11000000
                break
            default: break
                
            }
            array.append(command)
            array.append(UInt8(preset.midiCommands[i].data1))
            array.append(UInt8(preset.midiCommands[i].data2))
        }
        array.append(UInt8(preset.clock))
        peripheral.writeValue(Data(array), for: presetDataCharacteristic, type: CBCharacteristicWriteType.withResponse)
        print("update: \(array)")
    }
    
    func changePreset(bank: Int, preset: Int) {
        if peripheral == nil {
            return
        }
        var array = [UInt8]()
        array.append(UInt8((bank << 4) | preset))
        peripheral.writeValue(Data(array), for: currentPresetCharacteristic, type: CBCharacteristicWriteType.withResponse)
    }
}
