//
//  DetailView.swift
//  BLEDemo
//

import SwiftUI

struct DetailView: View {
    @EnvironmentObject var viewModel: BLEViewModel
    
    var body: some View {
        List {
            statusStack
            colorStack
            brightnessStack
            effectStack
        }
        .toolbar(content: {
            Group {
                Button(action: {
                    viewModel.disconnectPeripheral()
                    viewModel.stopScan()
                }) {
                    Text("Disconnect")
                }
                
                Button(action: {
                    viewModel.writeCommand(command: .getDeviceInfo)
                }, label: {
                    Text("Refresh")
                })
            }
        })
        .navigationBarTitle(viewModel.connectedDeviceName ?? "")
        .navigationBarBackButtonHidden(true)
    }
    
    var statusStack: some View {
        Toggle(isOn: $viewModel.status, label: {
            Text("Status")
        })
        .onReceive(viewModel.$status) { status in
            let command: Command = status ? .turnOn : .turnOff
            viewModel.writeCommand(command: command)
        }
    }
    
    var colorStack: some View {
        ColorPicker(selection: $viewModel.color, supportsOpacity: false) {
            Text("Color")
        }
        .onReceive(viewModel.$color) { color in
            viewModel.writeCommand(command: .setColor(color: color))
        }
    }
    
    var effectStack: some View {
        VStack(alignment: .leading) {
            Picker("Effect",
                   selection: $viewModel.effectB) {
                ForEach(Effect.allCases, id: \.self) {
                    Text($0.description)
                }
            }
            
            Slider(
                value: .init(get: {
                    Double(viewModel.effectSpeed)
                }, set: { value in
                    viewModel.effectSpeed = UInt8(value)
                }),
                in: 0...20
            ) {
                Text("Speed")
            } minimumValueLabel: {
                Text("Fast")
            } maximumValueLabel: {
                Text("Low")
            }
        }
        .onReceive(viewModel.$effectB) { effect in
            viewModel.writeCommand(command: .setEffect(effect: effect, speed: viewModel.effectSpeed))
        }
        .onReceive(viewModel.$effectSpeed) { speed in
            viewModel.writeCommand(command: .setEffect(effect: viewModel.effectB, speed: speed))
        }
    }
    
    var brightnessStack: some View {
        VStack(alignment: .leading) {
            Text("Brightness")
            Slider(
                value: .init(get: {
                    Double(viewModel.brightness)
                }, set: { value in
                    viewModel.brightness = UInt8(value)
                }),
                in: 0...255
            )
           }
        .onReceive(viewModel.$brightness) { value in
            viewModel.writeCommand(command: .setBrightness(value: value))
        }
    }
}
