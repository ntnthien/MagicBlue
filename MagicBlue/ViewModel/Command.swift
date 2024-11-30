//
//  Command.swift
//  MagicBlue
//
//  Created by Do Nguyen on 11/30/24.
//
import SwiftUI

enum Command {
    case turnOn
    case turnOff
    case setNotification
    case getDeviceInfo
    case setColor(color: Color)
    case setBrightness(value: UInt8)
    case setEffect(effect: Effect, speed: UInt8)
    
    var command: [UInt8] {
        switch self {
        case .turnOn:
            return [0xCC, 0x23, 0x33]
        case .turnOff:
            return [0xCC, 0x24, 0x33]
        case .setNotification:
            return [0x01, 0x00]
        case .getDeviceInfo:
            return [0xEF, 0x01, 0x77]
        case .setColor(let color):
            let colors = color.uInt8Array
            var command: [UInt8] = [0x56, 0x00, 0xF0, 0xAA]
            command.insert(contentsOf: colors, at: 1)
            return command
        case .setBrightness(let value):
            return [0x56, 0x00, 0x00, 0x00, value, 0x0F, 0xAA]
        case .setEffect(let effect, let speed):
            var speed = max(speed, 1)
            speed = min(speed, 20)
            return [0xBB, effect.rawValue, speed, 0x44]
        }
    }
}
