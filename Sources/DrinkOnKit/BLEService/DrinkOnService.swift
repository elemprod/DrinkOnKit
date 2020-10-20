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
     * The Raw Level Sensor Characteristic Notifications were Enabled or Disabled.
     *
     * - Parameter service:                 The DrinkOnService.
     * - Parameter enabled:                 Were notifications enabled?
     */
    func drinkOnService(_ service: DrinkOnService, didEnableLevelSensorCharNotification enabled : Bool)
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
    
    /**
     * Function for initiating a BLE Read of the Level Characteristic Value
     *  - returns: true if the service was previously discovered and has read access, else false.
    */
    public func readStatusChar() -> Bool {
        print("Reading Status Char")
        guard let statusChar = self.statusCharacteristic else {
            print("Status Characteristic Nil")
            let characteristics = [DrinkOnServiceIdentifiers.StatusCharUUID]
            self.peripheral.discoverCharacteristics(characteristics, for: self.service)
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
     * Function for handling a Status Characteristic update and making the delegate call.
     *  - returns: true if the update was sucessful else false.
    */
    fileprivate func processStatusCharUpdate() -> Bool {
        guard let statusChar = self.statusCharacteristic else {
            print("Status Characteristic Nil")
            return false
        }
        guard let data = statusChar.value,
              data.count == 10,
              let newGoal24hr24hrRaw : UInt8 = data.uint8ValueAt(index: 0),
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
        print("Reading Level Char")
        guard let levelSensorChar = self.levelSensorCharacteristic else {
            let characteristics = [DrinkOnServiceIdentifiers.LevelSensorCharUUID]
            self.peripheral.discoverCharacteristics(characteristics, for: self.service)
            return false
        }
        if levelSensorChar.properties.contains(.read) {
            levelSensorChar.service.peripheral.readValue(for: levelSensorChar)
            return true
        } else {
            print("Level Sensor Char. Missing Read Access")
            return false
        }
    }
    /**
     * Function for checking if  Level Sensor Characteristic Notifications are enabled
     *  - returns: true if notifications are currently enabled
    */
    public func levelSensorCharNotificationsEnabled() -> Bool {
        
        guard let levelSensorChar = self.levelSensorCharacteristic else {
            print("Level Sensor Char. Not Discovered")
            return false
        }
     
        return levelSensorChar.isNotifying
    }
    
    /**
     * Function for Initiating  an Enable / Disable of the Level Sensor Characteristic Notifications
     *
    */
    public func levelSensorCharNotifications(enable : Bool) {
        
        guard let levelSensorChar = self.levelSensorCharacteristic else {
            print("Level Sensor Char. Not Discovered")
            return
        }
    
        guard levelSensorChar.properties.contains(.notify) else {
            print("Level Sensor Char. Missing Notify Access")
            return
        }
        
        if enable == levelSensorChar.isNotifying {
            return     // Already enabled / disabled - nothing to do
        }
        
        levelSensorChar.service.peripheral.setNotifyValue(enable, for: levelSensorChar)
    }
    
    /**
     * Function for processing a Level Sensor Characteristic update and making the delegate call.
     *  - returns: true if the service was previously discovered and has read access, else false.
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
        print("Reading Info Char")
        guard let infoChar = self.infoCharacteristic else {
            let characteristics = [DrinkOnServiceIdentifiers.InfoCharUUID]
            self.peripheral.discoverCharacteristics(characteristics, for: self.service)
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
     * Function for processing a Info Characteristic update and making the delegate call.
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
        print("Reading Log Char")
        guard let logChar = self.logCharacteristic else {
            let characteristics = [DrinkOnServiceIdentifiers.LogCharUUID]
            self.peripheral.discoverCharacteristics(characteristics, for: self.service)
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
     * Function for processing a Log Characteristic update and making the delegate call.
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
        //print("Data Raw: "  + data.hexDescription)
        // Decompress the 18 logging bytes into 24 hourly data points
        var logValues : [Float] = []
        for index in stride(from: 1, to: 19, by: 3) {
            
            // Decompress 3 Log Bytes to 4 Raw Data Points
            guard let decompressedRaw : [UInt8] = data.decompressed423(index: index) else {
                print("Log Characteristic Update Failed")
                return false
            }
            logValues.append(Float(decompressedRaw[0]) / 10)
            logValues.append(Float(decompressedRaw[1]) / 10)
            logValues.append(Float(decompressedRaw[2]) / 10)
            logValues.append(Float(decompressedRaw[3]) / 10)
        }
        
        let logCharData = DrinkOnLogCharacteristic(logValues: logValues, offsett: Int(offsettHourRaw))
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
    internal init(service: CBService)  {
        self.service = service
    }
    
    internal func discoverCharacteristics(_ options : DrinkOnPeripheralOptions) {
        var characteristics : [CBUUID] = []
        
        if options.contains(.readStatusChar) {
            characteristics.append(DrinkOnServiceIdentifiers.StatusCharUUID)
        }
        
        if options.contains(.readInfoChar) {
            characteristics.append(DrinkOnServiceIdentifiers.InfoCharUUID)
        }
        
        if options.contains(.readLevelSensorChar) || options.contains(.notifyLevelSensorChar){
            characteristics.append(DrinkOnServiceIdentifiers.LevelSensorCharUUID)
        }
        
        if options.contains(.readLogChar) {
            characteristics.append(DrinkOnServiceIdentifiers.LogCharUUID)
        }
        
        if characteristics.count > 0 {
            self.service.peripheral.discoverCharacteristics(characteristics, for: self.service)
        } else {
            print("*** No Characteristics Selected")
        }
    }
    /**
     * The function handles service characteristic discovery call backs from the BLE Central Mananger.
     *
     * - parameter characteristics: An array of discovered characteristics.
     */
    internal func didDiscoverCharacteristics(characteristics: [CBCharacteristic], options : DrinkOnPeripheralOptions) {
        
        // Save the discovered Characteristic Reference
        for characteristic : CBCharacteristic in characteristics {
            switch characteristic.uuid {
            case DrinkOnServiceIdentifiers.StatusCharUUID:
                self.statusCharacteristic = characteristic
                print("Status Characteristic Discovered")

                if options.contains(.readStatusChar) {
                    _ = self.readStatusChar()
                }
                
            case DrinkOnServiceIdentifiers.LevelSensorCharUUID:
                self.levelSensorCharacteristic = characteristic
                print("Level Sensor Characteristic Discovered")
                
                if options.contains(.readLevelSensorChar) {
                    _ = self.readLevelSensorChar()
                }
                if options.contains(.notifyLevelSensorChar) {
                    self.levelSensorCharNotifications(enable: true)
                }

                
            case DrinkOnServiceIdentifiers.InfoCharUUID:
                self.infoCharacteristic = characteristic
                print("Info Characteristic Discovered")
                if options.contains(.readInfoChar) {
                    _ = self.readInfoChar()
                }
                
            case DrinkOnServiceIdentifiers.LogCharUUID:
                self.logCharacteristic = characteristic
                print("Log Characteristic Discovered")
                if options.contains(.readLogChar) {
                    _ = self.readLogChar()
                }
                
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
            print("Status Char Update")
            
        } else if characteristic === self.levelSensorCharacteristic {
            _ = processLevelSensorCharUpdate()
            print("Level Sensor Char. Update")
            
        } else if characteristic === self.infoCharacteristic {
            _ = processInfoCharUpdate()
            print("Info Char Update")
            
        } else if characteristic === self.logCharacteristic {
            _ = processLogCharUpdate()
            print("Log Char Update")
        } else {
            print("Unknown Characteristic")
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

        if characteristic === self.levelSensorCharacteristic {
            self.delegate?.drinkOnService(self, didEnableLevelSensorCharNotification: characteristic.isNotifying)
            print("Level Sensor  Notification Status Update")
            
        } else {
            print("Unknown Characteristic Notification Change")
        }
    }
    
}







