//
//  ContentView.swift
//  testble2
//
//  Created by Pawel Witkowski on 04/06/2021.
//

import SwiftUI
import PartialSheet

struct ContentView: View {
    @ObservedObject var ble: BLE

    var body: some View {
        VStack {
            if !ble.isConnected {
                ScanningView(ble: ble)
            } else {
                PresetView(ble: ble)
            }
        }.padding()
        .addPartialSheet()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(ble: BLE(isConnected: true))
    }
}
