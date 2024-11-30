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
    @Published var brightness: UInt8 = 0
    @Published var effectSpeed: UInt8 = 0
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
        isSearching = false
        isConnected = false
        
        foundPeripherals = []
        foundServices = []
        foundCharacteristics = []
    }
    
    func startScan() {
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
       
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
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
        service.characteristics?.forEach { characteristic in
            let setCharacteristic: ThermoCharacteristic = .init(uuid: characteristic.uuid,
                                                               readValue: nil,
                                                               service: characteristic.service!)
            foundCharacteristics.append(setCharacteristic)
            peripheral.readValue(for: characteristic)

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
            
            updateDeviceInfo(buffer: characteristicValue.uint8Array)
        }
        if let index = foundCharacteristics.firstIndex(where: { $0.uuid.uuidString == characteristic.uuid.uuidString }) {
            foundCharacteristics[index].readValue = Double(value)
            objectWillChange.send()
        }
    }
    
    func didWriteValue(_ peripheral: CBPeripheralProtocol, descriptor: CBDescriptor, error: Error?) {}
    
    func updateDeviceInfo(buffer: [UInt8]) {
//        var info: [String: Any] = [
//            "device_type": buffer[1],
//            "on": buffer[2] == 0x23,
//            "effect_no": buffer[3],
//            "effect_speed": buffer[5],
//            "r": buffer[6],
//            "g": buffer[7],
//            "b": buffer[8],
//            "brightness": buffer[9],
//            "version": buffer[10]
//        ]
        
        status = buffer[2] == 0x23
        
        if let effect = Effect(rawValue: buffer[3]) {
            effectB = effect
        }
        if #available(iOS 15.0, *) {
            let newColor: UIColor = .init(red: CGFloat(buffer[6]) / 255, green: CGFloat(buffer[7]) / 255, blue: CGFloat(buffer[8]) / 255, alpha: 1)
            self.color = Color(uiColor: newColor)
        } 
        brightness = buffer[9]
    }
    
    func writeCommand(command: Command, type: CBCharacteristicWriteType = .withoutResponse) {
        foundPeripherals.forEach { peripheral in
            guard let writeCharacteristic else { return }
            peripheral.peripheral.writeValue(Data(command.command),
                                             for: writeCharacteristic,
                                             type: type)
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

extension Data {
    var uint8Array: [UInt8] {
        var uint8Array = [UInt8](repeating: 0, count: self.count)

        self.withUnsafeBytes { buffer in
            guard let pointer = buffer.baseAddress else {
                // Handle the case where the buffer pointer is nil
                return
            }
            uint8Array = Array(UnsafeBufferPointer(start: pointer.assumingMemoryBound(to: UInt8.self), count: self.count))
        }
        return uint8Array
    }
}
