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

/// Data Object representing a DrinkOn BLE Peripheral
@available(iOS 13.0, *)
public class DrinkOnPeripheral: NSObject, Identifiable, ObservableObject, CBPeripheralDelegate, DrinkOnServiceDelegate {
    
    
    /// Is the DrinkOn Peripheral currently connected?
    //@Published public internal(set) var connected :Bool = false
    
    /// Uniquie ID number for the object
    public let id = UUID()
    
    /// Peripheral Connection State Definition
    @Published public internal(set) var state : CBPeripheralState
    
    /// Status Characteristic Data
    @Published public internal(set) var statusCharacteristic : DrinkOnStatusCharacteristic? = nil
    
    /// Info Characteristic Data
    @Published public internal(set) var infoCharacteristic : DrinkOnInfoCharacteristic? = nil
    
    /// Bottle Level Sensor in Raw Counts.
    @Published public internal(set) var levelSensor : Int? = nil
    
    /// An array of the user's water consumption for each of the previous hours with Units of Bottles consumed per Hour.
    @Published public internal(set) var consumed : [Float] = []
    
    /// Function for setting a new 24 hr liquid consumption gload with units of Bottls.
    public func goal24hrSet(goal : Float) {
        //TODO
        
    }
    
    /// Supported Service UUID's.
    fileprivate let serviceUUIDs                                        = [DrinkOnServiceIdentifiers.ServiceUUID]
    
    /// DrinkOn BLE Service
    internal var drinkOnService : DrinkOnService? = nil
    
    /// The CoreBluetooth Peripheral
    public internal(set) var peripheral : CBPeripheral
    
    
    /// The Peripheral Initializer.
    internal init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        self.state = peripheral.state
        print("Init: \(peripheral)")
    }
    
    // Was the connection attempt sucessful?
    internal var connectionSucceeded: Bool = false
        
    /**
     * Start Discovery of All Supported Services
     */
    internal func startServiceDiscovery() {
        print("Starting Service Discovery")
        peripheral.delegate = self                 // set the peripheral delegate to itself
        peripheral.discoverServices(serviceUUIDs)
    }
    
    /// The last BLE signal strength measurement
    public var RSSI : NSNumber? {
        return _RSSI
    }
    
    fileprivate var _RSSI : NSNumber? = nil {
        didSet(newValue){
            guard let newRSSI = newValue else {
                return
            }
            //delegate?.peripheral(self, didUpdateRSSI: newRSSI)
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
        _RSSI = RSSI
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
                if self.drinkOnService == nil {
                    let newService = DrinkOnService(service: service)
                    self.drinkOnService = newService
                    self.drinkOnService?.delegate = self
                    print("DrinkOn Service discovered")
                }
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
            drinkOnService?.didDiscoverCharacteristics(characteristics: characteristics)
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
        DispatchQueue.main.async {
            self.statusCharacteristic = data
        }
    }
    
    func drinkOnService(_ service: DrinkOnService, didUpdateLevelSensorChar levelSensor: Int) {
        if(self.levelSensor != levelSensor) {
            DispatchQueue.main.async {
                self.levelSensor = levelSensor
            }
        }
    }
    
    func drinkOnService(_ service: DrinkOnService, didUpdateInfoChar data: DrinkOnInfoCharacteristic) {
        // Don't need check if changed since the char is only read once
        DispatchQueue.main.async {
            self.infoCharacteristic = data
        }
    }
    
    func drinkOnService(_ service: DrinkOnService, didUpdateLogChar consumed: [Float]) {
        //TODO
    }
}
