//
//  Characteristic.swift
//  BLEDemo
//

import CoreBluetooth

class Characteristic: Identifiable {
    var id: UUID
    var characteristic: CBCharacteristic
    var description: String
    var uuid: CBUUID
    var readValue: String
    var service: CBService

    init(_characteristic: CBCharacteristic,
         _description: String,
         _uuid: CBUUID,
         _readValue: String,
         _service: CBService) {
        
        id = UUID()
        characteristic = _characteristic
        description = _description == "" ? "Unknown" : _description
        uuid = _uuid
        readValue = _readValue == "" ? "NoData" : _readValue
        service = _service
    }
}

extension Data.Element {
    var string: String {
        String(format:"%02x", self)
    }
}

extension Data {
    var string: String {
        String(data: self, encoding: .ascii) ?? "unknown"
    }
}

enum ThermoCharacteriticType: String {
    case temperature = "2A1F"
    case humidity = "2A6F"
    case unknown
    
    var description: String {
        switch self {
        case .temperature:
            return "Temperature"
        case .humidity:
            return "Humidity"
        case .unknown:
            return "Unknown"
        }
    }
}
class ThermoCharacteristic: Identifiable {
    
    var uuid: CBUUID
    var readValue: Double?
    var service: CBService
    
    var type: ThermoCharacteriticType {
        .init(rawValue: uuid.uuidString) ?? .unknown
    }

    var description: String {
        type.description
    }
    
    var stringValue: String {
        guard let readValue else { return "unknown"}
        
        switch type {
        case .humidity:
            return String("\(readValue / 100) (%)")
        case .temperature:
            return String("\(readValue / 10) (°C)")
        case .unknown:
            return String(readValue)
        }
    }
    
    init(uuid: CBUUID, readValue: Double?, service: CBService) {
        self.uuid = uuid
        self.readValue = readValue
        self.service = service
    }
}
