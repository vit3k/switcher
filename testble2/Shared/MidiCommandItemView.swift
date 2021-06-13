//
//  MidiCommandItemView.swift
//  testble2
//
//  Created by Pawel Witkowski on 12/06/2021.
//

import SwiftUI

struct MidiCommandItemView: View {
    var index: Int
    @Binding var cmd: MidiCommand
    var action: () -> Void

    func update() {
        action()
    }
    var body: some View {
        //print(cmd)
        return HStack {
            Text(String(index)).frame(width: 10)
            CustomPicker("Ch", selection: $cmd.channel, onChange: self.update) {
                ForEach((1...16), id: \.self) {
                    Text("\($0)").tag($0)
                }
            }.frame(width: 50)
            CustomPicker("", selection: $cmd.command, onChange: self.update) {
                Text("Empty").tag(MidiCommandType.Empty)
                Text("Program change").tag(MidiCommandType.ProgramChange)
                Text("Control change").tag(MidiCommandType.ControlChange)
            }.frame(width: 150)
            CustomPicker("", selection: $cmd.data1, onChange: self.update) {
                ForEach((0...127), id: \.self) {
                    Text("\($0)").tag($0)
                }
            }.frame(width: 50)
            CustomPicker("", selection: $cmd.data2, onChange: self.update) {
                ForEach((0...127), id: \.self) {
                    Text("\($0)").tag($0)
                }
            }.frame(width: 50)
        }
    }
}

struct MidiCommandItemView_Previews: PreviewProvider {
    static var previews: some View {
        MidiCommandItemView(index: 1, cmd: Binding.constant(MidiCommand(command: MidiCommandType.ProgramChange))) {
            print("test")
        }
    }
}
