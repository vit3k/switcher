//
//  CustomPicker.swift
//  testble2
//
//  Created by Pawel Witkowski on 12/06/2021.
//

import SwiftUI
import PartialSheet

struct CustomPicker<SelectionValue, Content> : View where SelectionValue : Hashable, Content : View {
    @EnvironmentObject var partialSheetManager: PartialSheetManager
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
        let binding = Binding (
            get: {self.selection},
            set: {self.selection = $0
                onChange()
            }
        )
        return Button(label) {
            print(label)
            partialSheetManager.showPartialSheet(onChange) {
                VStack {
                    Picker(label, selection: binding, content: content ).labelsHidden()
                    Button("Done") {
                        partialSheetManager.closePartialSheet()
                        onChange()
                    }
                }
            }
        }.foregroundColor(Color.blue)
    }
}

struct CustomPicker_Previews: PreviewProvider {
    static var previews: some View {
        CustomPicker("test", selection: Binding.constant(MidiCommandType.ProgramChange), onChange: {
            print("onchange")
        }) {
            Text("Empty").tag(MidiCommandType.Empty)
            Text("Program Change").tag(MidiCommandType.ProgramChange)
            Text("Control Change").tag(MidiCommandType.ControlChange)
        }.frame(width: 100)
    }
}
