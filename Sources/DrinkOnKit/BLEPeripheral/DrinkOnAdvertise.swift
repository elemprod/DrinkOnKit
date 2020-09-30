//
//  DrinkOnAdvertise.swift
//  DrinkOnKit
//
//  DrinkOn Advertising Data Objects
//  Created by Ben Wirz on 9/17/20.
//


import Foundation
import CoreBluetooth

/// DrinkOnKit Advertisement Type
@objc public enum DrinkOnAdvertiseType : Int {
    case link                                                   // Link Advertisement
    case level                                                  // Water Bottle Level Advertisement
    case level_raw                                              // Water Bottle Level Raw Advertisement
    case calibration                                            // Calibration Status Advertisement
}

/// DrinkOnKit Advertisement Length in Bytes for the Manufacturer Specific Advertisement Data
@objc public enum DrinkOnAdvertiseLength : Int {
    case link               = 0                                 // Link Advertisement
    case level              = 3                                 // Water Bottle Level Advertisement
    case level_raw          = 5                                 // Water Bottle Level Raw Advertisement
    case calibration        = 2                                 // Calibration Status Advertisement
}


/// Level Advertising Data Object
@objc public class DrinkOnAdvertise: NSObject {
    
    //static let DrinkOnManId : UInt8 = [0x33, 0x23]
    //static let DrinkOnAdvertiseTypeId : UInt8 = 0x11
    
    
    
}


