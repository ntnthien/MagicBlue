//
//  ListView.swift
//  BLEDemo
//

import SwiftUI

extension Array {
    public subscript(index: Int, default defaultValue: @autoclosure () -> Element) -> Element {
        guard index >= 0, index < endIndex else {
            return defaultValue()
        }
        
        return self[index]
    }
}

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
                        Section {
                            PeripheralCells()
                        } header: {
                            Toggle(isOn: $bleManager.isFilterEnabled) {
                                Text("Only Bulb Service UUID (\(BLEViewModel.Constants.serviceUUID))")
                            }
                        }
                    }
                }
            }
        }
        .onReceive(bleManager.$isFilterEnabled) { value in
            if bleManager.isSearching {
                bleManager.startScan()
            }
        }
        .navigationBarTitle("BLE Demo")
    }
    
    struct PeripheralCells: View {
        @EnvironmentObject var bleManager: BLEViewModel
        
        var body: some View {
            ForEach(bleManager.foundPeripherals, id: \.id) { peripheral in
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
