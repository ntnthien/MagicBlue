//
//  MagicBlueApp.swift
//  BLEDemo
//

import SwiftUI

@main
struct MagicBlueApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(BLEViewModel())
        }
    }
}
