//
//  ListView.swift
//  BLEDemo
//

import SwiftUI

struct ListView: View {
    @EnvironmentObject var bleManager: BLEViewModel
    
    var body: some View {
        ZStack {
            navigateToDetailView(isDetailViewLinkActive: $bleManager.isConnected)
            
            GeometryReader { proxy in
                VStack {
                    Button(action: {
                        if bleManager.isSearching {
                            bleManager.stopScan()
                        } else {
                            bleManager.startScan()
                        }
                    }) {
                        Text(bleManager.isSearching ? "Stop scanning" : "Start scanning")
                            .padding()
                            .foregroundColor(Color.blue)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.blue, lineWidth: 2))
                    }
                    
                    Text("Bluetooth state is \(bleManager.managerState.description)")
                        .font(.title3)
                        .padding(10)
                    
                    List {
                        PeripheralCells()
                    }
                }
            }
        }
        .navigationBarTitle("BLE Demo")
    }
    
    struct PeripheralCells: View {
        @EnvironmentObject var bleManager: BLEViewModel
        
        var body: some View {
            ForEach(0..<bleManager.foundPeripherals.count, id: \.self) { index in
                let peripheral = bleManager.foundPeripherals[index]
                Button(action: {
                    bleManager.connectPeripheral(peripheral)
                }) {
                    HStack {
                        Text("\(peripheral.name)")
                        Spacer()
                        Text("\(peripheral.rssi) dBm")
                    }
                }
            }
        }
    }
}
