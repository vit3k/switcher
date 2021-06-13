//
//  CustomPicker.swift
//  testble2
//
//  Created by Pawel Witkowski on 12/06/2021.
//

import SwiftUI

struct CustomPicker<SelectionValue, Content> : View where SelectionValue : Hashable, Content : View {
    var label: String
    @Binding var selection: SelectionValue
    var onChange: () -> Void
    var content: () -> Content
    
    public init(_ label: String, selection: Binding<SelectionValue>, onChange: @escaping () -> Void,
                @ViewBuilder content: @escaping () -> Content) {
        self.label = label
        self._selection = selection
        self.content = content
        self.onChange = onChange
    }
    
    var body: some View {
        let binding = Binding(
            get: { self.selection },
            set: { self.selection = $0
                onChange()
            }
        )
        return Picker(selection: binding.animation(), label: Text("\(label) \(String(describing: selection))")
                        .allowsTightening(false), content: content ).allowsTightening(false)
            .pickerStyle(MenuPickerStyle())
    }
}

struct CustomPicker_Previews: PreviewProvider {
    static var previews: some View {
        CustomPicker("", selection: Binding.constant(MidiCommandType.ProgramChange), onChange: {
            print("onchange")
        }) {
            Text("Program Chage ").tag(MidiCommandType.ProgramChange)
        }.frame(width: 100)
    }
}
