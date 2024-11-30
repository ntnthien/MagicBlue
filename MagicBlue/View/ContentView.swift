//
//  ContentView.swift
//  BLEDemo
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationView {
            ListView()
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}
