//
//  testble2App.swift
//  Shared
//
//  Created by Pawel Witkowski on 04/06/2021.
//

import SwiftUI

@main
struct testble2App: App {
    var body: some Scene {
        WindowGroup {
            ContentView(ble: BLE())
            //ContentView(ble: BLE(isConnected: true))
        }
    }
}
