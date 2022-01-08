//
//  ScanningView.swift
//  switcherui
//
//  Created by Pawel Witkowski on 14/06/2021.
//

import SwiftUI

struct ScanningView: View {
    @ObservedObject var ble: BLE
    var body: some View {
        VStack {
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
            Button("Force UI") {
                ble.isConnected = true
            }
        }
    }
}

struct ScanningView_Previews: PreviewProvider {
    static var previews: some View {
        ScanningView(ble: BLE())
    }
}
