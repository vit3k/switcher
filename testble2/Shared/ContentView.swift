//
//  ContentView.swift
//  testble2
//
//  Created by Pawel Witkowski on 04/06/2021.
//

import SwiftUI

struct ContentView: View {
    @ObservedObject var ble: BLE
    @State private var currentBank: Int = 0
    @State private var currentPreset: Int = 0
    var body: some View {
        VStack {
            if !ble.isConnected {
                if ble.isScanning {
                    ProgressView().progressViewStyle(CircularProgressViewStyle()).padding()
                } else {
                    Button("Scan", action: {
                        ble.scan()
                    }).padding()
                }
                List(ble.devices, id: \.self.identifier) { device in
                    HStack {
                        Text(device.name ?? device.identifier.uuidString)
                        Spacer()
                        if !ble.isConnected {
                            Button("Connect", action: {
                                ble.stopScan()
                                ble.connect(device: device)
                            })
                        } else {
                            Spacer()
                        }
                    }
                }
            } else {
                
                HStack {
                    CustomPicker("Bank", selection: $currentBank, onChange: {
                        print("bank change")
                        ble.changePreset(bank: currentBank, preset: currentPreset)
                    }) {
                        ForEach((0...4), id: \.self) {
                            Text("\($0)").tag($0)
                        }
                    }
                    CustomPicker("Preset", selection: $currentPreset, onChange: {
                        print("preset change")
                        ble.changePreset(bank: currentBank, preset: currentPreset)
                    }) {
                        ForEach((0...4), id: \.self) {
                            Text("\($0)").tag($0)
                        }
                    }
                }
                HStack {
                    Loopcheck(checked: $ble.preset.loops[0], text: "1") { ble.update() }
                    Loopcheck(checked: $ble.preset.loops[1], text: "2") { ble.update() }
                    Loopcheck(checked: $ble.preset.loops[2], text: "3") { ble.update() }
                    Loopcheck(checked: $ble.preset.loops[3], text: "4") { ble.update() }
                    Loopcheck(checked: $ble.preset.loops[4], text: "5") { ble.update() }
                    Loopcheck(checked: $ble.preset.loops[5], text: "6") { ble.update() }
                    Loopcheck(checked: $ble.preset.loops[6], text: "7") { ble.update() }
                    Loopcheck(checked: $ble.preset.loops[7], text: "8") { ble.update() }
                    Loopcheck(checked: $ble.preset.switch1, text: "S1") { ble.update() }
                }
                List {
                    ForEach(ble.preset.midiCommands.indices, id: \.self) { index in
                        MidiCommandItemView(index: index, cmd: $ble.preset.midiCommands[index]) {
                            ble.update()
                        }
                    }
                }
            }
        }.frame(minWidth: 200, maxWidth: .infinity, minHeight: 200, maxHeight: .infinity)
        .padding()
        .onChange(of: ble.preset, perform: { value in
            currentBank = ble.preset.bank
            currentPreset = ble.preset.preset
        })
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(ble: BLE(isConnected: true))
    }
}
