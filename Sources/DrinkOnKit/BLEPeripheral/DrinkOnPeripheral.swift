//
//  DrinkOnPeripheral.swift
//
//
//  Data Object for a DrinkOn BLE Peripheral
//
//

import Foundation
import CoreBluetooth



/// Status Characteristic Data Structure
public struct DrinkOnStatusCharacteristic {
    
    /// The user programmable liquid consumption goal per 24 hour period with units of Bottles.
    public let goal24hr : Float
    
    /// The Current bottle level as a Percentage (0 to 100)
    public let bottleLevel : Int

    /// The sum of the liquid consumed in the previous 24 hour period with units of Bottles.
    public let consumed24hr : Float
    
    /// The peripheral's current UI State Code.  Read Only
    public let UIStateCode : Int
    
    /// Battery Level as a Percentage (0 to 100) Read Only
    public let batteryLevel : Int
    
    /// The peripheral's total runtime in Hours.  Read Only
    public let runTime : Int
    
    /// Date when the characteristic was read from the DrinkOn Peripheral
    public let updated : Date
    
    /// Function for initializaing the structure with updated to set to the current Date.
    public init(goal24hr : Float,
                bottleLevel : Int,
                consumed24hr : Float,
                UIStateCode : Int,
                batteryLevel : Int,
                runTime : Int) {
        self.goal24hr = goal24hr
        self.bottleLevel = bottleLevel
        self.consumed24hr = consumed24hr
        self.UIStateCode = UIStateCode
        self.batteryLevel = batteryLevel
        self.runTime = runTime
        self.updated = Date()
    }

}

/// Info Characteristic Data Structure
public struct DrinkOnInfoCharacteristic {

    /// The peripheral's firmware version string in Major.Minor format.
    public let firmwareVersion : String

    /// The peripheral's DFU version code.
    public let dfuCode : Int
    
    /// The peripheral's model number.
    public let modelCode : Int
    
    /// The peripheral's hardware verison letter.
    public let hardwareCode : String
    
    /// Date when the characteristic was read from the DrinkOn Peripheral
    public let updated : Date
    
    /// Function for initializaing the structure with updated to set to the current Date.
    public init(firmwareVersion : String,
                dfuCode : Int,
                modelCode : Int,
                hardwareCode : String) {
        self.firmwareVersion = firmwareVersion
        self.dfuCode = dfuCode
        self.modelCode = modelCode
        self.hardwareCode = hardwareCode
        self.updated = Date()
    }
}

/// Liquid Level Sensor Characteristic Data Structure
/// Note that this characteristic is only used for debugging purposes and may not always be available.
public struct DrinkOnLevelSensorCharacteristic {
    
    /// Bottle Level Sensor in Raw Counts.
    public let levelSensor : Int
    
    /// Date when the characteristic was read from the DrinkOn Peripheral
    public let updated : Date
    
    /// Function for initializaing the structure with updated set to the current Date.
    public init(levelSensor : Int) {
        self.levelSensor = levelSensor
        self.updated = Date()
    }
}

/// Liquid Consumption Log Characteristic Data Structure
public struct DrinkOnLogCharacteristic {
    
    // A single log data point representing the liquid consumed during a 1 hour period
    public struct DrinkOnLogCharacteristicDataPoint : Identifiable {
        public let id : Int
        
        // The number of hours previous to now that the data point represents
        public var hour : Int {
            get {
                return id
            }
        }
        
        public let consumed : Float        // The liquid consumed in units of bottles during the hour
        
        public init(hour : Int, consumed : Float) {
            self.id = hour
            self.consumed = consumed
        }
    }
        
    /// An array of the user's liquid consumption for each of the previous hours with Units of Bottles consumed per Hour.
    public let log : [DrinkOnLogCharacteristicDataPoint]
    
    /// Date when the characteristic was read from the DrinkOn Peripheral
    public let updated : Date
    
    /// Function for initializaing the structure with an array of Data Points.
    public init(log : [DrinkOnLogCharacteristicDataPoint]) {
        self.log = log
        self.updated = Date()
    }
    
    /// Function for initializaing the structure with an ordered array of data point values and the hourly offsett for the first element of the array
    public init(logValues : [Float], offsett : Int) {
        var logDataPoints : [DrinkOnLogCharacteristicDataPoint] = []
        
        // Create log data points from value array
        for (index, value) in logValues.enumerated() {
            let newLogDataPoint = DrinkOnLogCharacteristicDataPoint(hour: index + offsett, consumed: value)
            logDataPoints.append(newLogDataPoint)
        }
        
        self.log = logDataPoints
        self.updated = Date()
    }
}

/***
 Option Set for Configuring Connections to a DrinkOn Peripheral.
 
 The default behaviour is to the connect to the Peripheral, read the characteristics selected in the option
 set and then disconnect from the Peripheral.  By only specifying the Characterstics containing the data values
 of interest, the shortest connection interval and corresponding lowest peripheral power consumption is achived.
 
 If the Info Characteristic has been previously read, it will not be read since the data fields are static, even if
 the readInfoChar characteristic is selected.
 
 */
public struct DrinkOnPeripheralOptions: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
         self.rawValue = rawValue
     }
    
    /// Disable automatic disconnection from the DrinkOn Peripheral once the specificed characteristics
    /// have been read.  The app is responsible for manually disconnecting the peripheral when this option.
    public static let disableDisconnect  = DrinkOnPeripheralOptions(rawValue: 1 << 0)
    
    /// Read the Status Characteristic after the connection is established.
    public static let readStatusChar    = DrinkOnPeripheralOptions(rawValue: 1 << 1)
    
    /// Read the Info Characteristic after the connection is established.
    public static let readInfoChar  = DrinkOnPeripheralOptions(rawValue: 1 << 2)
    
    /// Read the Level Sensor Characteristic after the connection is established.
    public static let readLevelSensorChar   = DrinkOnPeripheralOptions(rawValue: 1 << 3)
    
    /// Enable Level Sensor Characteristic Notificatons after the connection is established.
    /// The disableDisconnect option should also be selected so that the device is not disconnected automatically.
    public static let notifyLevelSensorChar   = DrinkOnPeripheralOptions(rawValue: 1 << 4)
    
    /// Read the Log Characteristic after the connection is established.
    public static let readLogChar  = DrinkOnPeripheralOptions(rawValue: 1 << 5)
    
    /// Combined Optionset to Read All Characteristics and then disconnect from the Peripheral
    public static let readAll : DrinkOnPeripheralOptions = [.readStatusChar, .readInfoChar, .readLevelSensorChar, .readLogChar]
    
    /// Combined Optionset to read all Sensor, Enable Level Sensor Notificatons and Disable Disconnection
    public static let enableLevelSensorNotifications : DrinkOnPeripheralOptions = [.readStatusChar, .readInfoChar, .notifyLevelSensorChar, .readLogChar, .disableDisconnect]
}

/***
 OptionSet for tracking whether  characteristics have been read and if notifications were enabled
 *
 * Note that the info characteristic updated status is not tracked here.  Since the data is static, we only need to
 * read it once and can therefore simply nil check the characteristic value to detemine if it has been previously read.
 */
public struct DrinkOnCharStatus: OptionSet {
    public let rawValue: Int

    public init(rawValue: Int) {
         self.rawValue = rawValue
     }

    /// Has the Status Characteristic been read?
    public static let statusCharUpdated    = DrinkOnCharStatus(rawValue: 1 << 0)
    
    /// Has the Level Sensor Characteristic been read?
    public static let levelSensorCharUpdated   = DrinkOnCharStatus(rawValue: 1 << 1)
    
    /// Have the Level Sensor Characteristic Notificatons been enabled?
    public static let levelSensorCharNotificationsEnabled   = DrinkOnCharStatus(rawValue: 1 << 2)
    
    /// Has the Log Characteristic been enabled?
    public static let logCharUpdated  = DrinkOnCharStatus(rawValue: 1 << 3)
    
    /// Combined Optionset with No Options Set
    public static let none : DrinkOnCharStatus = []
        
}

/// Data Object representing a DrinkOn BLE Peripheral
@available(iOS 13.0, *)
public class DrinkOnPeripheral: NSObject, Identifiable, ObservableObject, CBPeripheralDelegate, DrinkOnServiceDelegate {

    /// Uniquie ID number for the object
    public let id = UUID()
    
    /// Peripheral Connection State Definition
    @Published public internal(set) var state : CBPeripheralState
    
    /// Status Characteristic Data
    @Published public internal(set) var statusCharacteristic : DrinkOnStatusCharacteristic? = nil
    
    /// Info Characteristic Data
    @Published public internal(set) var infoCharacteristic : DrinkOnInfoCharacteristic? = nil
    
    /// Level Sensor Characteristic Data
    @Published public internal(set) var levelSensorCharacteristic : DrinkOnLevelSensorCharacteristic? = nil
    
    /// Liquid Consumption LOg Characteristic Data
    @Published public internal(set) var logCharacteristic : DrinkOnLogCharacteristic? = nil
    
    /// The last BLE signal strength measurement
    @Published public internal(set) var RSSI : NSNumber?
    
    /// Function for setting a new 24 hr liquid consumption gload with units of Bottls.
    public func goal24hrSet(goal : Float) {
        //TODO
        // value check, convert to uint8, send
    }
    
    /// Connection Options for the Peripheral
    public var options: DrinkOnPeripheralOptions
    
    // Characteristic status.
    private var charStatus : DrinkOnCharStatus = .none
    
    /// Connect the Peripheral
    public func connect() {
        DrinkOnKit.sharedInstance.connectPeripheral(self)
    }

    /// Connect the Peripheral with Options
    public func connect(options: DrinkOnPeripheralOptions) {
        self.options = options
        DrinkOnKit.sharedInstance.connectPeripheral(self)
    }
    
    
    /// Should the peripheral disconnect after notifications are disabled?
    private var disconnectQued : Bool = false
    
    public func levelSensorNotificationsEnable(_ enable : Bool) {
        guard let drinkOnService = self.drinkOnService else {
            return
        }
        drinkOnService.levelSensorCharNotifications(enable: enable)
    }
    
    /// Function for disabling peripheral notifications
    /// returns: true if the notifications disable was qued else false if there were no notifications to disable
    private func disableAllNotifications() -> Bool {
        
        guard let drinkOnService = self.drinkOnService else {
            return false
        }
        
        if drinkOnService.levelSensorCharNotificationsEnabled() {
            drinkOnService.levelSensorCharNotifications(enable: false)
            return true
        }
        return false
    }
    /// Disconnect the Peripheral
    public func disconnect() {
        
        // Disable notifications prior to disconnecting if required
        if self.disableAllNotifications() {
            disconnectQued = true
            return
        }
        
        DrinkOnKit.sharedInstance.disconnectPeripheral(self)
    }
    
    /// Supported Service UUID's.
    fileprivate let serviceUUIDs                                        = [DrinkOnServiceIdentifiers.ServiceUUID]
    
    /// DrinkOn BLE Service
    internal var drinkOnService : DrinkOnService? = nil
    
    /// The CoreBluetooth Peripheral
    public internal(set) var peripheral : CBPeripheral
    
    /// Initializer with a peripheral
    public convenience init(_ peripheral: CBPeripheral) {
        self.init(peripheral, options: DrinkOnPeripheralOptions.readAll)
    }
    
    /// Initializer with a peripheral and connection options.
    public init(_ peripheral: CBPeripheral, options: DrinkOnPeripheralOptions) {
        self.peripheral = peripheral
        self.state = peripheral.state
        self.options = options
        //print("Init: \(peripheral)")
    }
    
    /**
     * Start Discovery of All Supported Services
     */
    internal func startServiceDiscovery() {
        print("Starting Service Discovery")
        peripheral.delegate = self                 // set the peripheral delegate to itself
        peripheral.discoverServices(serviceUUIDs)
    }
    
    /// Function for checking if all of the characteristics selected in the options have been read
    /// and  automatically disconnecting if so
    private func autoDisconnectCheck() {
        
        if options.contains(.disableDisconnect) {   // auto disconnect disabled
            return
        }
        if options.contains(.readInfoChar) && infoCharacteristic == nil {
            return
        }
        if options.contains(.readLevelSensorChar) && !charStatus.contains(.levelSensorCharUpdated) {
            return
        }
        if options.contains(.readStatusChar) && !charStatus.contains(.statusCharUpdated) {
            return
        }
        if options.contains(.readLogChar) && !charStatus.contains(.logCharUpdated) {
            return
        }
        if options.contains(.enableLevelSensorNotifications) && !charStatus.contains(.levelSensorCharUpdated) {
            // make sure there was at least one update if level sensor notifications were enabled
            return
        }
        
        // all characteristics have been read so disconnect
        self.disconnect()
    }
    
    //MARK: CentralManager Update Functions
    
    /// Function to be called after the CentralManager Disconnects from the Peripheral
    internal func didDisconnect() {
        // The peripherals services [CBService] and characteristics [CBCharacteristic] are invalidated on disconnect
        self.drinkOnService = nil
        disconnectQued = false
        
        DispatchQueue.main.async {
            self.state = self.peripheral.state  // Update the observable state
        }
    }
    
    /// Function to be called after the CentralManager Connects with the Peripheral
    internal func didConnect() {
        
        // Clear the Characteristic Read & Notify Status
        charStatus = .none
        disconnectQued = false
        
        self.startServiceDiscovery()
        DispatchQueue.main.async {
            self.state = self.peripheral.state  // Update the observable state
        }
    }
    
    //MARK: CBPeripheral Delegate
    
    // Device Name Updated
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        
        // TODO update name
    }
    
    // Set any invalidated services to nil and attempt to rediscover it.
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        for invalidatedService : CBService in invalidatedServices {
            if invalidatedService.uuid .isEqual(DrinkOnServiceIdentifiers.ServiceUUID) {
                print("DrinkOn Service Invalidated")
                drinkOnService = nil
                peripheral.discoverServices([DrinkOnServiceIdentifiers.ServiceUUID])
            } else {
                print("Unrecognized Invalidated Service")
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didReadRSSI RSSI: NSNumber, error: Error?) {
        guard error == nil else {
            print("didReadRSSI Error: \(String(describing: error))")
            return
        }
        
        DispatchQueue.main.async {
            self.RSSI = RSSI
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("didDiscoverServices")
        guard error == nil else {
            print("didDiscoverServices Error: \(String(describing: error))")
            return
        }
        
        guard let services : [CBService] = peripheral.services else {
            print("didDiscoverServices - [Services] nil")
            return
        }
        
        for service : CBService in services {
            if service.uuid .isEqual(DrinkOnServiceIdentifiers.ServiceUUID) {
                // service characteristics are discovered during init
                let newService = DrinkOnService(service: service)
                self.drinkOnService = newService
                self.drinkOnService?.delegate = self
                var modifiedOptions = self.options
                if self.infoCharacteristic != nil {
                    modifiedOptions.remove(.readInfoChar)   // don't read info if previously read
                }
                self.drinkOnService?.discoverCharacteristics(modifiedOptions)
                print("DrinkOn Service discovered")
            } else {
                print("Unrecognized Service")
            }
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard error == nil else {
            print("didDiscoverCharacteristicsFor Error: \(String(describing: error))")
            return
        }
        guard let characteristics : [CBCharacteristic] = service.characteristics else {
            print("No Characteristics Found")
            return
        }
        // Call the discover characteristic methods for the matching service.
        if service === drinkOnService?.service {
            // The characteristic value is read if selected in the options
            drinkOnService?.didDiscoverCharacteristics(characteristics: characteristics, options : self.options)
        } else {
            print("Service Unrecognized: \(service)")
        }
        
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        guard error == nil else {
            print("didUpdateValueFor\n Char: \(characteristic.debugDescription)\n  Error: \(String(describing: error))")
            return
        }
        
        // Call the matching service didUpdateValue method
        if characteristic.service === drinkOnService?.service {
            drinkOnService?.didUpdateValueFor(characteristic: characteristic)
        } else {
            print("Service Not Recognized for Characteristic: \(characteristic)")
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        
        guard error == nil else {
            print("Characteristic \(characteristic) didWriteValueFor Error: \(String(describing: error))")
            return
        }
        
        // Call the matching service didWriteValue method
        if characteristic.service === drinkOnService?.service {
            drinkOnService?.didWriteValueFor(characteristic: characteristic, error: error)
        } else {
            print("Service Not Recognized for Characteristic: \(characteristic)")
        }
    }
    
    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        guard error == nil else {
            print("didUpdateNotificationStateFor Error: \(String(describing: error))")
            return
        }
        
        // Call the matching service didUpdateNotificationState method
        if characteristic.service === drinkOnService?.service {
            drinkOnService?.didUpdateNotificationStateFor(characteristic: characteristic)
        } else {
            print("Service Not Recognized for Characteristic: \(characteristic)")
        }
        
    }
    
    // No Implementation - included services are Secondary Services which isn't suppported by DrinkOn peripherals.
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverIncludedServicesFor service: CBService, error: Error?) {
        print("didDiscoverIncludedServicesFor Shouldn't be Called")
    }
    
    // No Implementation - only called if reading by descriptor which isn't suppported by DrinkOn peripherals.
    public func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor descriptor: CBDescriptor, error: Error?) {
        print("didUpdateValueFor Descriptor Shouldn't be Called")
    }
    
    // Not Implemented - only called if writing by descriptor which isn't suppported by DrinkOn peripherals.
    public func peripheral(_ peripheral: CBPeripheral, didWriteValueFor descriptor: CBDescriptor, error: Error?) {
        print("didWriteValueFor Descriptor Shouldn't be Called")
    }
    // Not Implemented - only called if discovering by descriptor which isn't suppported by DrinkOn peripherals.
    public func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        print("didDiscoverDescriptorsFor Shouldn't be Called")
    }
    
    
    //MARK: DrinkOnService Delegate
    func drinkOnService(_ service: DrinkOnService, didUpdateStatusChar data: DrinkOnStatusCharacteristic) {
        charStatus.insert(.statusCharUpdated)
        autoDisconnectCheck()
        DispatchQueue.main.async {
            print("Status Char Updated")
            self.statusCharacteristic = data
        }
    }
    
    func drinkOnService(_ service: DrinkOnService, didUpdateLevelSensorChar data: DrinkOnLevelSensorCharacteristic) {
        charStatus.insert(.levelSensorCharUpdated)
        autoDisconnectCheck()
        DispatchQueue.main.async {
            print("Level Sensor Char Updated")
            self.levelSensorCharacteristic = data
        }
    }
    
    func drinkOnService(_ service: DrinkOnService, didUpdateInfoChar data: DrinkOnInfoCharacteristic) {
        autoDisconnectCheck()
        DispatchQueue.main.async {
            print("Info Char Updated")
            self.infoCharacteristic = data
        }
    }
    
    func drinkOnService(_ service: DrinkOnService, didUpdateLogChar data: DrinkOnLogCharacteristic, offsett: Int) {
        charStatus.insert(.logCharUpdated)
        autoDisconnectCheck()
        DispatchQueue.main.async {
            print("Log Char Updated")
            // If the offsett is 0, just update the characterstic data with the new log
            if(offsett == 0) {
                self.logCharacteristic = data
            } else { // Append the new data with the old data
                guard let previousLog = self.logCharacteristic?.log else {
                    print("Prevous Log Point Empty")
                    return
                }
                if previousLog.count != offsett {
                    print("Logging Points Not Sequential-  Log Update Dropped")
                    return
                }
                // Append the previous log with the current log
                let combinedLog =  previousLog + data.log
                self.logCharacteristic = DrinkOnLogCharacteristic(log: combinedLog)
            }
            
        }
    }
    
    func drinkOnService(_ service: DrinkOnService, didEnableLevelSensorCharNotification enabled: Bool) {
        if enabled {
            charStatus.insert(.levelSensorCharNotificationsEnabled)
        } else if disconnectQued {
            self.disconnect()
            return
        }
        
        autoDisconnectCheck()
    }

}
