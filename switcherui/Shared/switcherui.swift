//
//  testble2App.swift
//  Shared
//
//  Created by Pawel Witkowski on 04/06/2021.
//

import SwiftUI
import PartialSheet

@main
struct switcherui: App {
    var body: some Scene {
        let sheetManager: PartialSheetManager = PartialSheetManager()
        WindowGroup {
            ContentView(ble: BLE())
            //ContentView(ble: BLE(isConnected: true))
                .environmentObject(sheetManager)
        }
    }
}
