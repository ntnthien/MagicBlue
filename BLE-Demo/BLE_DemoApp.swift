//
//  BLE_DemoApp.swift
//  BLEDemo
//

import SwiftUI

@main
struct BLE_DemoApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(BLEViewModel())
        }
    }
}
