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
        ColorPicker(selection: $viewModel.color) {
            Text("Color")
        }
        .onReceive(viewModel.$color) { color in
            viewModel.writeCommand(command: .setColor(color: color))
        }
    }
    
    var effectStack: some View {
        Picker("Effect",
               selection: $viewModel.effectB) {
            ForEach(Effect.allCases, id: \.self) {
                Text($0.description)
            }
        }
        .onReceive(viewModel.$effectB) { effect in
            viewModel.writeCommand(command: .setEffect(effect: effect, speed: 20))
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
