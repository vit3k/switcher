//
//  PresetView.swift
//  switcherui
//
//  Created by Pawel Witkowski on 14/06/2021.
//

import SwiftUI

struct Model<Content> where Content: View {
    @ViewBuilder var content: () -> Content
}

struct PresetView: View {
    @ObservedObject var ble: BLE
    @State private var currentBank: Int = 0
    @State private var currentPreset: Int = 0
    @State private var lastClockSliderEditing = false
    @State private var lastTap = Date()
    
    var body: some View {
        VStack {
            Text("Switcher App").font(.title)
            HStack {
                Button(action: {
                    currentPreset = currentPreset - 1
                    if currentPreset < 0 {
                        currentPreset = 4
                        currentBank = currentBank - 1
                        if currentBank < 0 {
                            currentBank = 4
                        }
                    }
                    ble.changePreset(bank: currentBank, preset: currentPreset)
                    
                }) {
                    Image(systemName: "arrow.backward.square.fill").font(.system(size: 40))
                }
                Spacer()
                CustomPicker("Bank \(currentBank)", selection: $currentBank, onChange: {
                    print("bank change")
                    ble.changePreset(bank: currentBank, preset: currentPreset)
                }) {
                    ForEach((0...4), id: \.self) {
                        Text("\($0)").tag($0)
                    }
                }
                CustomPicker("Preset \(currentPreset)", selection: $currentPreset, onChange: {
                    print("preset change")
                    ble.changePreset(bank: currentBank, preset: currentPreset)
                }) {
                    ForEach((0...4), id: \.self) {
                        Text("\($0)").tag($0)
                    }
                }
                Spacer()
                Button(action: {
                    currentPreset = currentPreset + 1
                    if currentPreset > 4 {
                        currentPreset = 0
                        currentBank = currentBank + 1
                        if currentBank > 4 {
                            currentBank = 0
                        }
                    }
                    ble.changePreset(bank: currentBank, preset: currentPreset)
                }) {
                    Image(systemName: "arrow.forward.square.fill").font(.system(size: 40))
                }
            }.padding()
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
            }.padding()
            List {
                ForEach(ble.preset.midiCommands.indices, id: \.self) { index in
                    MidiCommandItemView(index: index, cmd: $ble.preset.midiCommands[index]) {
                        ble.update()
                    }.buttonStyle(PlainButtonStyle()) // this is shit
                }
            }.padding().frame(maxHeight: 400)
            CustomPicker(ble.preset.clock == 0 ? "Clock Off" : "Clock: \(ble.preset.clock) BPM" , selection: $ble.preset.clock, onChange: { ble.update() }) {
                Text("Off").tag(0)
                ForEach((1...255), id: \.self) {
                    Text("\($0)").tag($0)
                }
            }
                
                /*Button("Tap") {
                    let current = Date()
                    let diff = current.timeIntervalSince(lastTap)
                    print(diff)
                    if diff > 3 {
                        lastTap = current
                        return
                    }
                    
                }.padding(EdgeInsets(top: 5, leading: 10, bottom: 5, trailing: 10))
                .background(Color(red: 0.85, green: 0.85, blue: 0.85))
                .clipShape(RoundedRectangle(cornerRadius: 10))*/
            
            
            Spacer()
        }
        
        .onChange(of: ble.preset, perform: { value in
            currentBank = ble.preset.bank
            currentPreset = ble.preset.preset
        })
    }
}

struct PresetView_Previews: PreviewProvider {
    static var previews: some View {
        PresetView(ble: BLE())
    }
}
