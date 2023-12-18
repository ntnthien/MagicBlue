//
//  DetailView.swift
//  BLEDemo
//

import SwiftUI

struct DetailView: View {
    @EnvironmentObject var viewModel: BLEViewModel
    
    
    var body: some View {
        GeometryReader { proxy in
            VStack {
                Button(action: {
                    viewModel.disconnectPeripheral()
                    viewModel.stopScan()
                }) {
                    Text("Disconnect")
                        .padding()
                        .foregroundColor(Color.blue)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.blue, lineWidth: 2))
                }
                Toggle(isOn: $viewModel.status, label: {
                    Text("Status")
                })

                ColorPicker(selection: $viewModel.color, label: {
                    Text("Color")
                }).frame(maxWidth: 200)
                
                Text("Bluetooth state is \(viewModel.managerState.description)")
                    .font(.title3)
                    .padding(10)
                
                Picker("Effect",
                       selection: $viewModel.effectB) {
                    ForEach(Effect.allCases, id: \.self) {
                        Text($0.description)
                    }
                }
                
                List {
                    CharacteriticCells()
                }
                .navigationBarTitle(viewModel.connectedDeviceName ?? "")
                .navigationBarBackButtonHidden(true)
            }
            .onReceive(viewModel.$color, perform: { color in
                viewModel.writeCommand(command: .setColor(color: color))
            })
            .onReceive(viewModel.$status, perform: { status in
                let command: Command = status ? .turnOn : .turnOff
                viewModel.writeCommand(command: command)
            })
            .onReceive(viewModel.$effectB, perform: { effect in
//                guard let effect else { return }
                viewModel.writeCommand(command: .setEffect(effect: effect, speed: 20))
            })
        }
    }
    
    struct CharacteriticCells: View {
        @EnvironmentObject var bleManager: BLEViewModel
        
        var body: some View {
            Section(header: Text("Chacracteristics")) {
                ForEach(0..<bleManager.foundCharacteristics.count, id: \.self) { charIndex in
                    let characteristic = bleManager.foundCharacteristics[charIndex]
                    VStack(alignment: .leading, spacing: 5) {
                        Text("uuid: \(characteristic.uuid.uuidString)")
                        Text("description: \(characteristic.description)")
                        Text("value: \(characteristic.stringValue)")
                    }
                }
            }
        }
    }
}
