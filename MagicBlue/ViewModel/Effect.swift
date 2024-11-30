//
//  Effect.swift
//  MagicBlue
//
//  Created by Do Nguyen on 11/30/24.
//

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
