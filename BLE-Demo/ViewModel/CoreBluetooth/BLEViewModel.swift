//
//  BLEViewModel.swift
//  BLEDemo
//

import SwiftUI
import CoreBluetooth
import Combine

extension String {
    var data: Data {
        var hex = self
        var data = Data()
        while(hex.count > 0) {
            let subIndex = hex.index(hex.startIndex, offsetBy: 2)
            let c = String(hex[..<subIndex])
            hex = String(hex[subIndex...])
            var ch: UInt64 = 0
            Scanner(string: c).scanHexInt64(&ch)
            var char = UInt8(ch)
            data.append(&char, count: 1)
        }
        return data
    }
}

extension CBManagerState {
    var description: String {
        switch(self){
        case .poweredOn:
            return "Powered On"
        case .poweredOff:
            return "Powered Off"
        case .resetting:
            return "Resetting"
        case .unauthorized:
            return "Unauthorized"
        default:
            return "Unknown"
        }
    }
}
class BLEViewModel: NSObject, ObservableObject {
    struct Constants {
        static let serviceUUID = "FFE5"
        static let readCharacteristic = "FFE4"
        static let writeCharacteristic = "FFE9"
    }
    
    @Published var managerState: CBManagerState = .unknown
    @Published var isSearching: Bool = false
    @Published var isConnected: Bool = false
    @Published var foundPeripherals: [Peripheral] = []
    @Published var foundServices: [Service] = []
    @Published var foundCharacteristics: [ThermoCharacteristic] = []
    @Published var connectedDeviceName: String?
    @Published var color: Color = .red
    @Published var status: Bool = false
    @Published var effectB: Effect = .blueGradualChange
    @Published var isFilterEnabled: Bool = false

    var readCharacteristic : CBCharacteristic!
    var writeCharacteristic : CBCharacteristic!

    private var centralManager: CBCentralManagerProtocol!
    private var connectedPeripheral: Peripheral!
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
    }
    
    private func resetConfigure() {
//        withAnimation {
            isSearching = false
            isConnected = false
            
            foundPeripherals = []
            foundServices = []
            foundCharacteristics = []
//        }
    }
    
    func startScan() {
//        resetConfigure()
        resetConfigure()
        let services: [CBUUID]? = isFilterEnabled ? [.init(string: Constants.serviceUUID)] : nil
        let scanOption = [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        centralManager?.scanForPeripherals(withServices: services, options: scanOption)
        print("# Start Scan")
        isSearching = true
    }
    
    func stopScan(){
        centralManager?.stopScan()
        print("# Stop Scan")
        isSearching = false
    }
    
    func connectPeripheral(_ selectPeripheral: Peripheral?) {
        guard let connectPeripheral = selectPeripheral else { return }
        connectedPeripheral = selectPeripheral
        centralManager.connect(connectPeripheral.peripheral, options: nil)
    }
    
    func disconnectPeripheral() {
        guard let connectedPeripheral = connectedPeripheral else { return }
        centralManager.cancelPeripheralConnection(connectedPeripheral.peripheral)
    }
}

// MARK: - CoreBluetooth CentralManager Delegete Func
extension BLEViewModel: CBCentralManagerProtocolDelegate {
    func didUpdateState(_ central: CBCentralManagerProtocol) {
        managerState = central.state
    }
    
    func didDiscover(_ central: CBCentralManagerProtocol, peripheral: CBPeripheralProtocol, advertisementData: [String : Any], rssi: NSNumber) {
        if rssi.intValue >= 0 { return }
        let peripheralName = advertisementData[CBAdvertisementDataLocalNameKey] as? String ?? nil
        var _name = "Unknown"
        
        if let peripheralName {
            _name = String(peripheralName)
        } else if let name = peripheral.name {
            _name = String(name)
        }
      
        let foundPeripheral: Peripheral = Peripheral(_peripheral: peripheral,
                                                     _name: _name,
                                                     _advData: advertisementData,
                                                     _rssi: rssi,
                                                     _discoverCount: 0)
        
        if let index = foundPeripherals.firstIndex(where: { $0.peripheral.identifier.uuidString == peripheral.identifier.uuidString }) {
                foundPeripherals[index].name = _name
                foundPeripherals[index].rssi = rssi.intValue
                foundPeripherals[index].discoverCount += 1
        } else {
            foundPeripherals.append(foundPeripheral)
        }
    }
    
    func didConnect(_ central: CBCentralManagerProtocol, peripheral: CBPeripheralProtocol) {
        guard let connectedPeripheral = connectedPeripheral else { return }
        print("Connected!")

        isConnected = true
        connectedPeripheral.peripheral.delegate = self
        connectedPeripheral.peripheral.discoverServices(nil)
        connectedDeviceName = peripheral.name
       
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.writeCommand(command: .getDeviceInfo)

        }
    }
    
    func didFailToConnect(_ central: CBCentralManagerProtocol, peripheral: CBPeripheralProtocol, error: Error?) {
        disconnectPeripheral()
    }
    
    func didDisconnect(_ central: CBCentralManagerProtocol, peripheral: CBPeripheralProtocol, error: Error?) {
        print("Disconnected!!!")
        resetConfigure()
    }
    
    func connectionEventDidOccur(_ central: CBCentralManagerProtocol, event: CBConnectionEvent, peripheral: CBPeripheralProtocol) {}
    
    func willRestoreState(_ central: CBCentralManagerProtocol, dict: [String : Any]) {}
    
    func didUpdateANCSAuthorization(_ central: CBCentralManagerProtocol, peripheral: CBPeripheralProtocol) {}
}

// MARK: - CoreBluetooth Peripheral Delegate Func
extension BLEViewModel: CBPeripheralProtocolDelegate {
    func didDiscoverServices(_ peripheral: CBPeripheralProtocol, error: Error?) {
        peripheral.services?.forEach { service in
            let setService = Service(_uuid: service.uuid, _service: service)
            foundServices.append(setService)
           
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }
    
    func didDiscoverCharacteristics(_ peripheral: CBPeripheralProtocol, service: CBService, error: Error?) {
//        guard service.uuid.uuidString == Constants.serviceUUID else { return }
        service.characteristics?.forEach { characteristic in
            let setCharacteristic: ThermoCharacteristic = .init(uuid: characteristic.uuid,
                                                               readValue: nil,
                                                               service: characteristic.service!)
//            if setCharacteristic.type != .unknown {
                foundCharacteristics.append(setCharacteristic)
                peripheral.readValue(for: characteristic)
//                peripheral.setNotifyValue(true, for: characteristic)
//            }
            
            if characteristic.uuid.uuidString == Constants.readCharacteristic {
                readCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: readCharacteristic)

                peripheral.writeValue(Data(Command.setNotification.command),
                                                 for: readCharacteristic,
                                      type: .withResponse)
            } else if characteristic.uuid.uuidString == Constants.writeCharacteristic {
                writeCharacteristic = characteristic
            }
        }
    }
    
    func didUpdateValue(_ peripheral: CBPeripheralProtocol, characteristic: CBCharacteristic, error: Error?) {
        guard
              let characteristicValue = characteristic.value else { return }
        
        let value = characteristicValue.withUnsafeBytes { $0.load(as: UInt8.self) }
        
        print("value \(characteristicValue) - len: \(characteristicValue.count) - \(value.hexString)")
        if characteristicValue.count >= 11 && characteristicValue[0] == 0x66 && characteristicValue[11] == 0x99 {
            print("device info")
            
            
        }
        if let index = foundCharacteristics.firstIndex(where: { $0.uuid.uuidString == characteristic.uuid.uuidString }) {
            foundCharacteristics[index].readValue = Double(value)
            objectWillChange.send()
        }
    }
    
    func didWriteValue(_ peripheral: CBPeripheralProtocol, descriptor: CBDescriptor, error: Error?) {

    }
    
//    func subscribeToRecvCharacteristic() {
//        guard let char = _recvCharacteristic else {
//            // Handle the case where _recvCharacteristic is nil
//            return
//        }
//        var char = writeCharacteristic
//        let handle = char?.value + 1
//        var msg = Data([0x01, 0x00])
//        
//        _connection.writeCharacteristic(handle, value: &msg)
//    }
    
    static func decodeDeviceInfo(buffer: [UInt8]) -> [String: Any] {
           var info: [String: Any] = [
               "device_type": buffer[1],
               "on": buffer[2] == 0x23,
               "effect_no": buffer[3],
               "effect_speed": buffer[5],
               "r": buffer[6],
               "g": buffer[7],
               "b": buffer[8],
               "brightness": buffer[9],
               "version": buffer[10]
           ]

//           do {
//               if let effectNo = info["effect_no"] as? Int {
//                   info["effect"] = try Effect(effectNo)
//               }
//           } catch {
//               // Handle the error as needed
//           }

           return info
       }
    
    func writeCommand(command: Command, type: CBCharacteristicWriteType = .withoutResponse) {
        foundPeripherals.forEach { peripheral in
            guard let writeCharacteristic else { return }
            peripheral.peripheral.writeValue(Data(command.command),
                                             for: writeCharacteristic,
                                             type: type)
        }
    }
    
//    func publishColorChange(_ color: Color) {
//        let colors = color.uInt8Array
//        var command: [UInt8] = [0x56, 0x00, 0xF0, 0xAA]
//        commands.insert(contentsOf: colors, at: 1)
//        foundPeripherals.forEach { peripheral in
//            guard let writeCharacteristic else { return }
//            peripheral.peripheral.writeValue(Data(command),
//                                             for: writeCharacteristic,
//                                             type: .withoutResponse)
//        }
//    }
}

enum Effect: UInt8, CaseIterable {
    case sevenColorCrossFade = 0x25
    case redGradualChange = 0x26
    case greenGradualChange = 0x27
    case blueGradualChange = 0x28
    case yellowGradualChange = 0x29
    case cyanGradualChange = 0x2a
    case purpleGradualChange = 0x2b
    case whiteGradualChange = 0x2c
    case redGreenCrossFade = 0x2d
    case redBlueCrossFade = 0x2e
    case greenBlueCrossFade = 0x2f
    case sevenColorStrobeFlash = 0x30
    case redStrobeFlash = 0x31
    case greenStrobeFlash = 0x32
    case blueStrobeFlash = 0x33
    case yellowStrobeFlash = 0x34
    case cyanStrobeFlash = 0x35
    case purpleStrobeFlash = 0x36
    case whiteStrobeFlash = 0x37
    case sevenColorJumpingChange = 0x38
    
    var description: String {
        switch self {
        case .sevenColorCrossFade: return "Seven Color Cross Fade"
        case .redGradualChange: return "Red Gradual Change"
        case .greenGradualChange: return "Green Gradual Change"
        case .blueGradualChange: return "Blue Gradual Change"
        case .yellowGradualChange: return "Yellow Gradual Change"
        case .cyanGradualChange: return "Cyan Gradual Change"
        case .purpleGradualChange: return "Purple Gradual Change"
        case .whiteGradualChange: return "White Gradual Change"
        case .redGreenCrossFade: return "Red Green Cross Fade"
        case .redBlueCrossFade: return "Red Blue Cross Fade"
        case .greenBlueCrossFade: return "Green Blue Cross Fade"
        case .sevenColorStrobeFlash: return "Seven Color Strobe Flash"
        case .redStrobeFlash: return "Red Strobe Flash"
        case .greenStrobeFlash: return "Green Strobe Flash"
        case .blueStrobeFlash: return "Blue Strobe Flash"
        case .yellowStrobeFlash: return "Yellow Strobe Flash"
        case .cyanStrobeFlash: return "Cyan Strobe Flash"
        case .purpleStrobeFlash: return "Purple Strobe Flash"
        case .whiteStrobeFlash: return "White Strobe Flash"
        case .sevenColorJumpingChange: return "Seven Color Jumping Change"
        }
    }
}

enum Command {
    case turnOn
    case turnOff
    case setNotification
    case getDeviceInfo
    case setColor(color: Color)
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
        case .setEffect(let effect, let speed):
            var speed = max(speed, 1)
            speed = max(speed, 20)
            var command: [UInt8] = [0xBB, effect.rawValue, speed, 0x44]
            return command
        }
    }
}
extension Color {
    var uInt8Array: [UInt8] {
        let components = cgColor?.components
        let r: CGFloat = components?[0] ?? 0.0
        let g: CGFloat = components?[1] ?? 0.0
        let b: CGFloat = components?[2] ?? 0.0
        
        let roundR = UInt8(Float(r * 255))
        let roundG = UInt8(Float(g * 255))
        let roundB = UInt8(Float(b * 255))
        
        return [roundR, roundG, roundB]
    }
}

extension UInt8 {
    var hexString: String {
        "0x" + String(self, radix: 16, uppercase: true)
    }
}
