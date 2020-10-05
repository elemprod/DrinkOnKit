//
//  DOPeripheral.swift
//
//
//  Data Object for a DrinkOn BLE Peripheral
//
//

import Foundation
import CoreBluetooth

/// DrinkOn Peripheral Delegate
@available(iOS 13.0, *)
public protocol DrinkOnPeripheralDelegate: class {
    /**
     * The peripheral's RSSI value was updated.
     *
     * - Parameter peripheral:      The peripheral.
     * - Parameter RSSI:            The updated RSSI value.
     */
    //func peripheral(_ peripheral: DrinkOnPeripheral, didUpdateRSSI RSSI: NSNumber)
    
    /**
     * The peripheral's DrinkOn BLE Service was discovered.
     *
     * - Parameter peripheral:      The Peripheral.
     * - Parameter service:         The DrinkOn Service.
     */
    //func peripheral(_ peripheral: DrinkOnPeripheral, didDiscoverDrinkOnService service: DrinkOnService)
    
}

/// Data Object representing a DrinkOn BLE Peripheral
@available(iOS 13.0, *)
public class DrinkOnPeripheral: NSObject, Identifiable, ObservableObject, CBPeripheralDelegate, DrinkOnServiceDelegate {
    
    /// Uniquie ID number for the object
    public let id = UUID()
    
    /// Is the peripheral currently connected?
    @Published public internal(set) var connected :Bool = false
    
    /// The Current bottle level as a Percentage (0 to 100)
    @Published public internal(set) var bottleLevel : Int? = nil

    /// The Current bottle Level Sensor in Raw Counts.
    @Published public internal(set) var levelSensor : Int? = nil
    
    /// The sum of the liquid consumed in the previous 24 hour period with units of Bottles.
    @Published public internal(set) var consumed24hr : Float? = nil
    
    /// The peripheral's current UI State Code.
    @Published public internal(set) var UIStateCode : Int? = nil
    
    /// The user programmable liquid consumption goal per 24 hour period with units of Bottles.
    @Published public internal(set) var goal24hr : Float? = nil
    
    /// Function for setting a new 24 hr liquid consumption gload with units of Bottls.
    public func goal24hrSet(goal : Float) {
        //TODO
        
    }
    /// The peripheral's raw liquid level sensor with units of Sensor Counts. Read Only
    @Published public internal(set) var liquidLevelRaw : Int? = nil
    
    /// Battery Level as a Percentage (0 to 100) Read Only
    @Published public internal(set) var batteryLevel : Int? = nil
    
    /// The peripheral's total runtime in Hours.  Read Only
    @Published public internal(set) var runTime : Int? = nil
    
    /// The peripheral's firmware version string in Major.Minor format.  Read Only
    @Published public internal(set) var firmwareVersion : String? = nil

    /// The peripheral's DFU version code  Read Only
    @Published public internal(set) var dfuCode : Int? = nil
    
    /// The peripheral's model number.  Read Only
    @Published public internal(set) var modelCode : Int? = nil
    
    /// The peripheral's hardware verison letter.  Read Only
    @Published public internal(set) var hardwareCode : String? = nil
    
    /// An array of the user's water consumption for each of the previous hours with Units of Bottles consumed per Hour.  Read Only
    @Published public internal(set) var consumed : [Float] = []
    
    
    /// Supported Service UUID's.
    fileprivate let serviceUUIDs                                        = [DrinkOnServiceIdentifiers.ServiceUUID]
    
    /// DrinkOn BLE Service
    public var drinkOnService : DrinkOnService? = nil
    
    /// The CoreBluetooth Peripheral
    public internal(set) var peripheral : CBPeripheral
    
    /**
     * The Peripheral Initializer.
     * Note that the DrinkOnPeripheral's delegate must be set to CBPeripheralDelegate after the initializer returns
     * so that the peripheral receives the peripheral delegate callbacks.
     */
    internal init(peripheral: CBPeripheral) {
        self.peripheral = peripheral
        print("Init: \(peripheral)")
    }
    
    // Was the connection attempt sucessful?
    internal var connectionSucceeded: Bool = false
    
    /// The peripheral's delegate.
    weak var delegate : DrinkOnPeripheralDelegate?
    
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
    func drinkOnService(_ service: DrinkOnService, didUpdateStatusChar data: DrinkOnServiceStatusCharData) {
        DispatchQueue.main.async {
            if(self.goal24hr != data.goal24hr ) {
                self.goal24hr = data.goal24hr
            }
            if(self.bottleLevel != data.bottleLevel) {
                self.bottleLevel = data.bottleLevel
                print("Bottle Level Update: " + String(data.bottleLevel))
            }
            if(self.consumed24hr != data.consumed24hr) {
                self.consumed24hr = data.consumed24hr
            }
            if(self.UIStateCode != data.UIStateCode) {
                self.UIStateCode = data.UIStateCode
            }
            if(self.batteryLevel != data.batteryLevel) {
                self.batteryLevel = data.batteryLevel
            }
            if(self.runTime != data.runTime) {
                self.runTime = data.runTime
            }
        }
    }
    
    func drinkOnService(_ service: DrinkOnService, didUpdateLevelSensorChar levelSensor: Int) {
        if(self.levelSensor != levelSensor) {
            DispatchQueue.main.async {
                self.levelSensor = levelSensor
            }
        }
    }
    
    func drinkOnService(_ service: DrinkOnService, didUpdateInfoChar data: DrinkOnServiceInfoCharData) {
        // Don't need check if changed since the char is only read once
        DispatchQueue.main.async {
            self.firmwareVersion = data.firmwareVersion
            self.dfuCode = data.dfuCode
            self.modelCode = data.modelCode
            self.hardwareCode = data.hardwareCode
        }
    }
    
    func drinkOnService(_ service: DrinkOnService, didUpdateLogChar consumed: [Float]) {
        //TODO
    }
}
