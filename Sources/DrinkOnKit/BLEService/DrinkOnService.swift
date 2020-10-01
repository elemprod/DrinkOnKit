//
//  DrinkOnService.swift
//
//  Data Object for a DrinkOn BLE Service
//

import Foundation
import CoreBluetooth

/// DrinkOn BLE Service & Characteristic Identifiers
internal class DrinkOnServiceIdentifiers: NSObject {
    
    /// DrinkOn Service Base UUID
    static let ServiceUUIDString                    = "E5BA1000-B46E-7188-A34B-A74651E22E9D"
    static let ServiceUUID                          = CBUUID(string: ServiceUUIDString)
    
    /// Level Characteristic UUID
    static let LevelCharUUIDString                  = "E5BA1001-B46E-7188-A34B-A74651E22E9D"
    static let LevelCharUUID                        = CBUUID(string: LevelCharUUIDString)
    
    /// Level Sensor Raw Characteristic UUID
    static let LevelSensorCharUUIDString            = "E5BA1002-B46E-7188-A34B-A74651E22E9D"
    static let LevelSensorCharUUID                  = CBUUID(string: LevelSensorCharUUIDString)
    
    /// Status Characteristic UUID
    static let StatusCharUUIDString                 = "E5BA1003-B46E-7188-A34B-A74651E22E9D"
    static let StatusCharUUID                       = CBUUID(string: StatusCharUUIDString)
    
    /// Log Characteristic UUID
    static let LogCharUUIDString                    = "E5BA1004-B46E-7188-A34B-A74651E22E9D"
    static let LogCharUUID                          = CBUUID(string: LogCharUUIDString)
}

/// Service Delegate
@available(iOS 13.0, *)
public protocol DrinkOnServiceDelegate: class {
    
    
    /**
     * The Level Characteristics was discovered.
     *
     * - Parameter service:                 The service.
     * - Parameter valid:                   True if the characteristics are valid.
     */
    func drinkOnService(_ service: DrinkOnService, levelCharValid : Bool)
}

/**
 * Bit array enumeration for storing the BLE status for the DrinkOn Service Chracateristics.
 * Used to protect the device from too frequent BLE's accesses and validating characteristics.
 *
 * _Discovered indicates the characteristic was discovered and is valid.
 * _Valid indicates the characteristic was discovered and is valid.
 * _ReadLocked indicates the Charactersitic was recently Read
 * _WriteLocked indicates a Characteristic Write is in progress.
 * _NotificationEn indicates Notifications are Enabled for a Characteristic
 */
fileprivate struct DrinkOnServiceCharState: OptionSet {
    let rawValue: Int
    
    // Level Characteristic State
    static let levelDiscovered                  = DrinkOnServiceCharState(rawValue: 1 << 0)
    static let levelValid                       = DrinkOnServiceCharState(rawValue: 1 << 1)
    static let levelReadLocked                  = DrinkOnServiceCharState(rawValue: 1 << 2)
    static let levelWriteLocked                 = DrinkOnServiceCharState(rawValue: 1 << 3)
    
    // Level Sensor Characteristic State
    static let levelSensorDiscovered            = DrinkOnServiceCharState(rawValue: 1 << 4)
    static let levelSensorValid                 = DrinkOnServiceCharState(rawValue: 1 << 5)
    static let levelSensorReadLocked            = DrinkOnServiceCharState(rawValue: 1 << 6)
    static let levelSensorNotificationEn        = DrinkOnServiceCharState(rawValue: 1 << 7)
    
    // Status Characteristic State
    static let statusDiscovered                 = DrinkOnServiceCharState(rawValue: 1 << 8)
    static let statusValid                      = DrinkOnServiceCharState(rawValue: 1 << 9)
    static let statusReadLocked                 = DrinkOnServiceCharState(rawValue: 1 << 10)
    
    // Log Characteristic State
    static let logDiscovered                 = DrinkOnServiceCharState(rawValue: 1 << 11)
    static let logValid                      = DrinkOnServiceCharState(rawValue: 1 << 12)
    static let logReadLocked                 = DrinkOnServiceCharState(rawValue: 1 << 13)
    
}


@available(iOS 13.0, *)
public class DrinkOnService: ObservableObject {
    
    
    /// The Current bottle level as a Percentage (0.0 to 1.0)  Read Only
    @Published public internal(set) var bottleLevel : Int? = nil

    /// The Current bottle Level Sensor in Raw Counts.  Read Only
    @Published public internal(set) var levelSensor : Int? = nil
    
    /// The sum of the liquid consumed in the previous 24 hour period with units of Bottles. Read Only
    @Published public internal(set) var consumed24hr : Double? = nil
    
    /// The user programmable liquid consumption goal per 24 hour period with units of Bottles.  Read & Write
    @Published public var goal24hr : Double? = nil
    
    /// The peripheral's raw liquid level sensor with units of Sensor Counts. Read Only
    @Published public internal(set) var liquidLevelRaw : Int? = nil
    
    /// Battery Level as a Percentage (0 to 100) Read Only
    @Published public internal(set) var batteryLevel : Int? = nil
    
    /// The peripheral's total runtime in Hours.  Read Only
    @Published public internal(set) var runTime : Int? = nil
    
    /// The peripheral's firmware version string in Major.Minor format.  Read Only
    @Published public internal(set) var version : String? = nil

    /// The peripheral's DFU version code  Read Only
    @Published public internal(set) var dfuCode : Int? = nil
    
    /// The peripheral's model number.  Read Only
    @Published public internal(set) var model : Int? = nil
    
    /// The peripheral's hardware verison letter.  Read Only
    @Published public internal(set) var hardwareCode : String? = nil
    
    /// An array of the user's water consumption for each of the previous hours with Units of Bottles consumed per Hour.  Read Only
    @Published public internal(set) var consumed : [Float] = []
    
    
    /// The Bluetooth Peripheral for the service.
    public var peripheral : CBPeripheral {
        get {
            return service.peripheral
        }
    }
    
    
    /// The Service Delegate.
    public weak var delegate : DrinkOnServiceDelegate?
    
    /// Service and Characteristic References
    internal var service                        : CBService
    fileprivate var levelCharacteristic         : CBCharacteristic?  = nil
    fileprivate var levelSensorCharacteristic   : CBCharacteristic?  = nil
    fileprivate var statusCharacteristic        : CBCharacteristic?  = nil
    fileprivate var logCharacteristic           : CBCharacteristic?  = nil
    
    /// Characteristic status flags
    fileprivate var charState                   : DrinkOnServiceCharState
    
    /**
     * Function for initiating a BLE Read of the Level Characteristic Value
     *  - returns: true if the service was previously discovered and has read access, else false.
    */
    public func readLevelChar() -> Bool {
        guard let levelCharacteristic = self.levelCharacteristic else {
            return false
        }
        if(levelCharacteristic.properties.contains(.read)) {
            levelCharacteristic.service.peripheral.readValue(for: levelCharacteristic)
            return true
        } else {
            print("Level Char. Missing Read Access")
            return false
        }
    }
    
    /**
     * Function for updating the observable variables with updated Level Characteristic data
     *  - returns: true if the update was sucessful else false.
    */
    fileprivate func updateLevelChar() -> Bool {
        guard let levelCharacteristic = self.levelCharacteristic else {
            print("Level Characteristic Nil")
            return false
        }
        guard let data = levelCharacteristic.value,
              data.count == 3,
              let newBottleLevelRaw : Int8 = data.int8ValueAt(index: 0),
              let newConsumed24hrRaw : Int8 = data.int8ValueAt(index: 1),
              let newGoal24hr24hrRaw : Int8 = data.int8ValueAt(index: 2)
             else {
                print("Level Characteristic Update Failed")
                return false
            }
        
        // Scale the Raw Values
        let newBottleLevel : Int = Int(newBottleLevelRaw)
        let newConsumed24hr : Double = Double(newConsumed24hrRaw / 10)
        let newGoal24hr24hr : Double = Double(newGoal24hr24hrRaw / 10)
        DispatchQueue.main.async {
            self.bottleLevel = newBottleLevel
            self.consumed24hr = newConsumed24hr
            self.goal24hr = newGoal24hr24hr
        }
        return true
    }
    
    /**
     * Function for initiating a BLE Read of the Level Sensor Characteristic Value
     *  - returns: true if the service was previously discovered and has read access, else false.
    */
    public func readLevelSensorChar() -> Bool {
        guard let levelSensorCharacteristic = self.levelSensorCharacteristic else {
            return false
        }
        if(levelSensorCharacteristic.properties.contains(.read)) {
            levelSensorCharacteristic.service.peripheral.readValue(for: levelSensorCharacteristic)
            return true
        } else {
            print("Level Sensor Char. Missing Read Access")
            return false
        }
    }
    
    /**
     * Function for updating the observable variables with updated Level Sensor Characteristic data
     *  - returns: true if the update was sucessful else false.
    */
    fileprivate func updateLevelSensorChar() -> Bool {
        guard let levelSensorCharacteristic = self.levelSensorCharacteristic else {
            print("Level Sensor Characteristic Nil")
            return false
        }
        guard let data = levelSensorCharacteristic.value,
              data.count == 4,
              let newLevelSensorRaw : UInt32 = data.uint32ValueAt(index: 0)
             else {
                print("Level Sensor Characteristic Update Failed")
                return false
            }
        
        let newLevelSensor : Int = Int(newLevelSensorRaw)
        DispatchQueue.main.async {
            self.levelSensor = newLevelSensor
        }
        return true
    }
    
    
    /**
     * Function for initiating a BLE Read of the Status Characteristic Value
     *  - returns: true if the service was previously discovered and has read access, else false.
    */
    public func readStatusChar() -> Bool {
        guard let statusCharacteristic = self.statusCharacteristic else {
            return false
        }
        if(statusCharacteristic.properties.contains(.read)) {
            statusCharacteristic.service.peripheral.readValue(for: statusCharacteristic)
            return true
        } else {
            print("Status Char. Missing Read Access")
            return false
        }
    }
    
    
    //update status and log char functions
    
    
    /**
     * Function for initiating a BLE Read of the Log Characteristic Value
     *  - returns: true if the service was previously discovered and has read access, else false.
    */
    public func readLogChar() -> Bool {
        guard let logCharacteristic = self.logCharacteristic else {
            return false
        }
        if(logCharacteristic.properties.contains(.read)) {
            logCharacteristic.service.peripheral.readValue(for: logCharacteristic)
            return true
        } else {
            print("Log Char. Missing Read Access")
            return false
        }
    }
    
    /**
     * The class initialzaer.
     *
     * Attempts to disccover all of the known charactertistics for the service.
     *
     * - parameter service: The Central Manager supplied service reference.
     */
    internal init(service: CBService) {
        self.service = service
        charState = []
        
        //TODO don't discover the characteristics until accessed to save BLE traffic??
        
        // Discover the Service Characteristics
        let characteristics = [DrinkOnServiceIdentifiers.LevelCharUUID, DrinkOnServiceIdentifiers.LevelSensorCharUUID, DrinkOnServiceIdentifiers.StatusCharUUID, DrinkOnServiceIdentifiers.LogCharUUID]
        service.peripheral.discoverCharacteristics(characteristics, for: service)
    }
    
    /**
     * The function handles service characteristic discovery call backs from the BLE Central Mananger.
     *
     * - parameter characteristics: An array of discovered characteristics.
     */
    internal func didDiscoverCharacteristics(characteristics: [CBCharacteristic]) {
        
        // Save the discovered Characteristic Reference
        for characteristic : CBCharacteristic in characteristics {
            switch characteristic.uuid {
            case DrinkOnServiceIdentifiers.LevelCharUUID:
                self.levelCharacteristic = characteristic
                print("Level Characteristic Discovered")
                _ = self.readLevelChar()
                
            case DrinkOnServiceIdentifiers.LevelSensorCharUUID:
                self.levelSensorCharacteristic = characteristic
                print("Level Sensor Characteristic Discovered")
                _ = self.readLevelSensorChar()
                
            case DrinkOnServiceIdentifiers.StatusCharUUID:
                self.statusCharacteristic = characteristic
                print("Status Characteristic Discovered")
                _ = self.readStatusChar()
                
            case DrinkOnServiceIdentifiers.LogCharUUID:
                self.logCharacteristic = characteristic
                print("Log Characteristic Discovered")
                _ = self.readLogChar()
                
            default:
                print("didDiscoverCharacteristicsFor - Unrecognized Characteristic \(characteristic.debugDescription)")
            }
        }
    }
    
    /**
     *  The function handles characteristic value updates call backs from the BLE Central Mananger.
     *
     * - parameter characteristic:          The characteristic
     */
    internal func didUpdateValueFor(characteristic: CBCharacteristic) {
        
        if(characteristic === self.levelCharacteristic) {
            print("Level Char Read")
        }
        
    }
    
    /**
     *  The function handles characteristic value write call backs from the BLE Central Mananger.
     *
     * - parameter characteristic:          The characteristic
     */
    internal func didWriteValueFor(characteristic: CBCharacteristic, error: Error?) {
        
    }
    
    /**
     *  The function handles characteristic notification state call backs from the BLE Central Mananger.
     *
     * - parameter characteristic:          The characteristic
     */
    internal func didUpdateNotificationStateFor(characteristic: CBCharacteristic) {
        //TODO set the notification state flags
    }
    
    
}







