//
//  ScannedPeripheral.swift
//
//  Data Object for a single BLE Scanned Peripheral
//

import Foundation
import CoreBluetooth

/// Data Object representing a single DrinkOn BLE Peripheral detected during a BLE scan.
@available(iOS 13.0, *)
public class ScannedDrinkOnPeripheral: Identifiable, ObservableObject {
    
    /// Uniquie ID number for the object
    public let id = UUID()
    
    /// The Peripheral assigned by CoreBluetooth and used to connect to the device.
    @Published public internal(set) var peripheral  : CBPeripheral
    
    /// The DrinkOn Peripheral.
    @Published public internal(set) var drinkOnPeripheral  : DrinkOnPeripheral
    
    /// The last radio signal strength measurement in dBm.
    @Published public internal(set) var rssi : Double? = nil {
        didSet {
            rssiUpdated = Date()
        }
    }
    
    /// Date when the radio signal strength measurement was last updated
    public internal(set) var rssiUpdated : Date?
    
    /// The advertised current bottle level as a percentage (0.0 to 1.0)
    @Published public internal(set) var level : Double? = nil
    
    /// The advertised liquid consumed in the the previous 24 hour period in units of bottles.
    @Published public internal(set) var consumed24hrs : Double? = nil
    
    /// Is the peripheral currently connected?
    @Published public internal(set) var connected : Bool = false
    
    
    /// BLE Device Name of the Scanned Peripheral
    public var name: String {
        get {
            guard let peripheralName = peripheral.name else {
                return "Uknown"
            }
            return peripheralName
        }
    }
    
    public init(_ peripheral : CBPeripheral) {
        self.peripheral = peripheral
        self.drinkOnPeripheral = DrinkOnPeripheral(peripheral)
        rssi = nil
    }
    
    public  init(_ peripheral : CBPeripheral, andRSSI anRSSI:Double?) {
        self.peripheral = peripheral
        self.drinkOnPeripheral = DrinkOnPeripheral(peripheral)
        rssi = anRSSI
    }
    
    public static func == (lhs: ScannedDrinkOnPeripheral, rhs: ScannedDrinkOnPeripheral) -> Bool {
        lhs.id == rhs.id
    }
    
    public func isEqual(_ object: Any?) -> Bool {
        if let otherPeripheral = object as? ScannedDrinkOnPeripheral {
            return peripheral == otherPeripheral.peripheral
        }
        return false
    }
    
    
}
