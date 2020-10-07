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
    
    /// Status Characteristic UUID
    static let StatusCharUUIDString                 = "E5BA1001-B46E-7188-A34B-A74651E22E9D"
    static let StatusCharUUID                       = CBUUID(string: StatusCharUUIDString)
    
    /// Level Sensor Raw Characteristic UUID
    static let LevelSensorCharUUIDString            = "E5BA1002-B46E-7188-A34B-A74651E22E9D"
    static let LevelSensorCharUUID                  = CBUUID(string: LevelSensorCharUUIDString)
    
    /// Info Characteristic UUID
    static let InfoCharUUIDString                   = "E5BA1003-B46E-7188-A34B-A74651E22E9D"
    static let InfoCharUUID                         = CBUUID(string: InfoCharUUIDString)
    
    /// Log Characteristic UUID
    static let LogCharUUIDString                    = "E5BA1004-B46E-7188-A34B-A74651E22E9D"
    static let LogCharUUID                          = CBUUID(string: LogCharUUIDString)
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
    
    // Status Characteristic State
    static let statusDiscovered                  = DrinkOnServiceCharState(rawValue: 1 << 0)
    static let statusValid                       = DrinkOnServiceCharState(rawValue: 1 << 1)
    static let statusReadLocked                  = DrinkOnServiceCharState(rawValue: 1 << 2)
    static let statusWriteLocked                 = DrinkOnServiceCharState(rawValue: 1 << 3)
    
    // Level Sensor Characteristic State
    static let levelSensorDiscovered            = DrinkOnServiceCharState(rawValue: 1 << 4)
    static let levelSensorValid                 = DrinkOnServiceCharState(rawValue: 1 << 5)
    static let levelSensorReadLocked            = DrinkOnServiceCharState(rawValue: 1 << 6)
    static let levelSensorNotificationEn        = DrinkOnServiceCharState(rawValue: 1 << 7)
    
    // Info Characteristic State
    static let infoDiscovered                   = DrinkOnServiceCharState(rawValue: 1 << 8)
    static let infoRead                         = DrinkOnServiceCharState(rawValue: 1 << 10)
    
    // Log Characteristic State
    static let logDiscovered                 = DrinkOnServiceCharState(rawValue: 1 << 11)
    static let logValid                      = DrinkOnServiceCharState(rawValue: 1 << 12)
    static let logReadLocked                 = DrinkOnServiceCharState(rawValue: 1 << 13)
    
}



/// Service Delegate
@available(iOS 10.0, *)
internal protocol DrinkOnServiceDelegate: class {
    
    /**
     * The Status Characteristic was updated.
     *
     * - Parameter service:                 The DrinkOnService.
     * - Parameter data:                    The updated Data
     */
    func drinkOnService(_ service: DrinkOnService, didUpdateStatusChar  data : DrinkOnStatusCharacteristic)
    

    /**
     * The Raw Level Sensor Characteristic was updated.
     *
     * - Parameter service:                 The DrinkOnService.
     * - Parameter data:                     The updated Characteristic Data
     */
    func drinkOnService(_ service: DrinkOnService, didUpdateLevelSensorChar  data : DrinkOnLevelSensorCharacteristic)
    
    /**
     * The Info Characteristic was updated.
     *
     * - Parameter service:                 The DrinkOnService.
     * - Parameter data:                    The updated Characteristic Data
     */
    func drinkOnService(_ service: DrinkOnService, didUpdateInfoChar  data : DrinkOnInfoCharacteristic)
    
    /**
     * The Log Characteristic was updated.
     *
     * - Parameter service:                 The DrinkOnService.
     * - Parameter data:                    The updated Characteristic Data
     */
    func drinkOnService(_ service: DrinkOnService, didUpdateLogChar data : DrinkOnLogCharacteristic, offsett: Int)
}


@available(iOS 10.0, *)
public class DrinkOnService {
        
    /// The Bluetooth Peripheral for the service.
    internal var peripheral : CBPeripheral {
        get {
            return service.peripheral
        }
    }
    
    /// The Service Delegate.
    internal weak var delegate : DrinkOnServiceDelegate?
    
    /// Service and Characteristic References
    internal var service                        : CBService
    fileprivate var statusCharacteristic        : CBCharacteristic?  = nil
    fileprivate var levelSensorCharacteristic   : CBCharacteristic?  = nil
    fileprivate var infoCharacteristic          : CBCharacteristic?  = nil
    fileprivate var logCharacteristic           : CBCharacteristic?  = nil
    
    /// Characteristic status flags
    fileprivate var charState                   : DrinkOnServiceCharState
    
    /**
     * Function for initiating a BLE Read of the Level Characteristic Value
     *  - returns: true if the service was previously discovered and has read access, else false.
    */
    public func readStatusChar() -> Bool {
        guard let statusChar = self.statusCharacteristic else {
            print("Status Characteristic Nil")
            return false
        }
        if(statusChar.properties.contains(.read)) {
            statusChar.service.peripheral.readValue(for: statusChar)
            return true
        } else {
            print("Status Char. Missing Read Access")
            return false
        }
    }
    
    
    /**
     * Function for handling a Status Characteristic write and making the delegate call.
     *  - returns: true if the update was sucessful else false.
    */
    fileprivate func processStatusCharUpdate() -> Bool {
        guard let statusChar = self.statusCharacteristic else {
            print("Status Characteristic Nil")
            return false
        }
        guard let data = statusChar.value,
              data.count == 10,
              let newGoal24hr24hrRaw : Int8 = data.int8ValueAt(index: 0),
              let newBottleLevelRaw : Int8 = data.int8ValueAt(index: 1),
              let newConsumed24hrRaw : Float = data.floatValueAt(index: 2),
              let newUIStateCodeRaw : UInt8 = data.uint8ValueAt(index: 6),
              let newBatteryLevelRaw : Int8 = data.int8ValueAt(index: 7),
              let newRunTimeRaw : UInt16 = data.uint16ValueAt(index: 8)
             else {
                print("Status Characteristic Update Failed")
                return false
            }
    
        // Scale and store the the Raw Values
        let statusData : DrinkOnStatusCharacteristic
            = DrinkOnStatusCharacteristic(goal24hr: Float(newGoal24hr24hrRaw / 10),
                                           bottleLevel: Int(newBottleLevelRaw),
                                           consumed24hr: newConsumed24hrRaw,
                                           UIStateCode: Int(newUIStateCodeRaw),
                                           batteryLevel: Int(newBatteryLevelRaw),
                                           runTime: Int(newRunTimeRaw))
        // Make the delegate call with the updated data
        delegate?.drinkOnService(self, didUpdateStatusChar: statusData)
        return true
    }
    
    /**
     * Function for initiating a BLE Read of the Level Sensor Characteristic Value
     *  - returns: true if the service was previously discovered and has read access, else false.
    */
    public func readLevelSensorChar() -> Bool {
        guard let levelSensorChar = self.levelSensorCharacteristic else {
            return false
        }
        if(levelSensorChar.properties.contains(.read)) {
            levelSensorChar.service.peripheral.readValue(for: levelSensorChar)
            return true
        } else {
            print("Level Sensor Char. Missing Read Access")
            return false
        }
    }
    
    /**
     * Function for processing a Level Sensor Characteristic write and making the delegate call.
     *  - returns: true if the update was sucessful else false.
    */
    fileprivate func processLevelSensorCharUpdate() -> Bool {
        guard let levelSensorChar = self.levelSensorCharacteristic else {
            print("Level Sensor Characteristic Nil")
            return false
        }
        guard let data = levelSensorChar.value,
              data.count == 4,
              let newLevelSensorRaw : Int32 = data.int32ValueAt(index: 0)
        else {
            print("Level Sensor Characteristic Update Failed")
            return false
        }
        let levelSensorData : DrinkOnLevelSensorCharacteristic = DrinkOnLevelSensorCharacteristic(levelSensor: Int(newLevelSensorRaw))
        delegate?.drinkOnService(self, didUpdateLevelSensorChar: levelSensorData)
        return true
    }
    
    
    /**
     * Function for initiating a BLE Read of the Info Characteristic Value
     *  - returns: true if the service was previously discovered and has read access, else false.
    */
    public func readInfoChar() -> Bool {
        guard let infoChar = self.infoCharacteristic else {
            return false
        }
        if(infoChar.properties.contains(.read)) {
            infoChar.service.peripheral.readValue(for: infoChar)
            return true
        } else {
            print("Info. Characteristic Missing Read Access")
            return false
        }
    }
    
    /**
     * Function for processing a Info Characteristic write and making the delegate call.
     *  - returns: true if the update was sucessful else false.
    */
    fileprivate func processInfoCharUpdate() -> Bool {
        guard let infoChar = self.infoCharacteristic else {
            print("Info Characteristic Nil")
            return false
        }
        guard let data = infoChar.value,
              data.count == 6,
              let newFirmwareMajorVerRaw : UInt8 = data.uint8ValueAt(index: 0),
              let newFirmwareMinorVerRaw : UInt8 = data.uint8ValueAt(index: 1),
              let newDFUCodeRaw : UInt8 = data.uint8ValueAt(index: 2),
              let newModelCodeRaw : UInt16 = data.uint16ValueAt(index: 3),
              let newHardwareCodeRaw : UInt8 = data.uint8ValueAt(index: 5)
             else {
                print("Info Characteristic Update Failed")
                return false
            }
        
        let infoCharData : DrinkOnInfoCharacteristic = DrinkOnInfoCharacteristic(
            firmwareVersion: String(newFirmwareMajorVerRaw) + "." + String(newFirmwareMinorVerRaw),
            dfuCode: Int(newDFUCodeRaw),
            modelCode: Int(newModelCodeRaw),
            hardwareCode: String(UnicodeScalar(newHardwareCodeRaw))
        )

        self.delegate?.drinkOnService(self, didUpdateInfoChar: infoCharData)
        return true
    }

    /**
     * Function for initiating a BLE Read of the Log Characteristic Value
     *  - returns: true if the service was previously discovered and has read access, else false.
    */
    public func readLogChar() -> Bool {
        guard let logChar = self.logCharacteristic else {
            return false
        }
        if(logChar.properties.contains(.read)) {
            logChar.service.peripheral.readValue(for: logChar)
            return true
        } else {
            print("Log Char. Missing Read Access")
            return false
        }
    }
    
    
    /**
     * Function for processing a Log Characteristic write and making the delegate call.
     *  - returns: true if the update was sucessful else false.
    */
    fileprivate func processLogCharUpdate() -> Bool {
        guard let logChar = self.logCharacteristic else {
            print("Log Characteristic Nil")
            return false
        }
        guard let data = logChar.value,
              data.count == 19,
              let offsettHourRaw : UInt8 = data.uint8ValueAt(index: 0)
             else {
                print("Log Characteristic Update Failed")
                return false
            }
        
        // Decompress the 18 logging bytes into 24 hourly data points
        var logValues : [Float] = []
        for index in stride(from: 1, to: 16, by: 3) {
            
            // Decompress 3 Log Bytes to 4 Raw Data Points
            guard let decompressedRaw : [UInt8] = data.decompressed423(index: index) else {
                print("Log Characteristic Update Failed")
                return false
            }
            logValues.append(Float(decompressedRaw[0] / 10))
            logValues.append(Float(decompressedRaw[1] / 10))
            logValues.append(Float(decompressedRaw[2] / 10))
            logValues.append(Float(decompressedRaw[3] / 10))
        }
        
        let logCharData = DrinkOnLogCharacteristic(logValues: logValues, firstOffsettHour: Int(offsettHourRaw))
        self.delegate?.drinkOnService(self, didUpdateLogChar: logCharData, offsett: Int(offsettHourRaw))
        return true
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
        
        // Discover all of the Service Characteristics at Init
        let characteristics = [DrinkOnServiceIdentifiers.StatusCharUUID, DrinkOnServiceIdentifiers.LevelSensorCharUUID, DrinkOnServiceIdentifiers.InfoCharUUID, DrinkOnServiceIdentifiers.LogCharUUID]
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
            case DrinkOnServiceIdentifiers.StatusCharUUID:
                self.statusCharacteristic = characteristic
                print("Status Characteristic Discovered")
                _ = self.readStatusChar()
                
            case DrinkOnServiceIdentifiers.LevelSensorCharUUID:
                self.levelSensorCharacteristic = characteristic
                print("Level Sensor Characteristic Discovered")
                _ = self.readLevelSensorChar()
                
            case DrinkOnServiceIdentifiers.InfoCharUUID:
                self.infoCharacteristic = characteristic
                print("Info Characteristic Discovered")
                _ = self.readInfoChar()
                
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
        
        if characteristic === self.statusCharacteristic {
            _ = processStatusCharUpdate()
            print("Status Char Read")
            
        } else if characteristic === self.levelSensorCharacteristic {
            _ = processLevelSensorCharUpdate()
            print("Level Sensor Char. Read")
            
        } else if characteristic === self.infoCharacteristic {
            _ = processInfoCharUpdate()
            print("Info Char Read")
            
        } else if characteristic === self.logCharacteristic {
            //TODO process log update
            print("Log Char Read")
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







