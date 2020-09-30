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
    func peripheral(_ peripheral: DrinkOnPeripheral, didUpdateRSSI RSSI: NSNumber)
    
    /**
     * The peripheral's DrinkOn BLE Service was discovered.
     *
     * - Parameter peripheral:      The Peripheral.
     * - Parameter service:         The DrinkOn Service.
     */
    func peripheral(_ peripheral: DrinkOnPeripheral, didDiscoverDrinkOnService service: DrinkOnService)
    
}

/// Data Object representing a single DrinkOn BLE Peripheral
@available(iOS 13.0, *)
public class DrinkOnPeripheral: NSObject, Identifiable, ObservableObject, CBPeripheralDelegate {
    
    /// Supported Service UUID's.
    fileprivate let serviceUUIDs                                        = [DrinkOnServiceIdentifiers.DrinkOnServiceUUID]
    
    /// Uniquie ID number for the object
    public let id = UUID()
    
    /// Is the peripheral connected?
    public var connected : Bool {
        return peripheral.state == .connected
    }
    
    
    /// Current bottle level as a percentage (0.0 to 1.0)
    @Published public internal(set) var level : Double? = nil
    
    
    
    /**
     * The Peripheral Initializer.
     * Note that the DrinkOnPeripheral's delegate must be set to CBPeripheralDelegate after the initializer returns
     * so that the peripheral receives the peripheral delegate callbacks.
     */
    internal init(withPeripheral peripheral: CBPeripheral) {
        _peripheral = peripheral
        print("Init: \(peripheral)")
    }
    
    // Was the connection attempt sucessful?
    internal var connectionSucceeded: Bool = false
    
    
    /// The underlying Bluetooth Peripheral
    public var peripheral : CBPeripheral {
        return _peripheral
    }
    fileprivate var _peripheral : CBPeripheral
    
    /// The peripheral's delegate.
    weak var delegate : DrinkOnPeripheralDelegate?
    
    
    
    /**
     * Start Discovery of All Supported Services
     */
    internal func startServiceDiscovery() {
        print("Starting Service Discovery")
        _peripheral.delegate = self                 // set the peripheral delegate to itself
        _peripheral.discoverServices(serviceUUIDs)
    }
    
    /// DrinkOn BLE Service
    @Published public internal(set) var drinkOnService : DrinkOnService? = nil
    
    /// The last BLE signal strength measurement
    public var RSSI : NSNumber? {
        return _RSSI
    }
    
    fileprivate var _RSSI : NSNumber? = nil {
        didSet(newValue){
            guard let newRSSI = newValue else {
                return
            }
            delegate?.peripheral(self, didUpdateRSSI: newRSSI)
        }
    }
    
    //MARK: CBPeripheral Delegate
    
    // Device Name Updated
    public func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
        
        // TODO call delegate
    }
    
    // Set any invalidated services to nil and attempt to rediscover it.
    public func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        for invalidatedService : CBService in invalidatedServices {
            if invalidatedService.uuid .isEqual(DrinkOnServiceIdentifiers.DrinkOnServiceUUID) {
                print("DrinkOn Service Invalidated")
                drinkOnService = nil
                peripheral.discoverServices([DrinkOnServiceIdentifiers.DrinkOnServiceUUID])
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
            if service.uuid .isEqual(DrinkOnServiceIdentifiers.DrinkOnServiceUUID) {
                if drinkOnService == nil {
                    let newService = DrinkOnService(service: service)
                    drinkOnService = newService
                    delegate?.peripheral(self, didDiscoverDrinkOnService: newService)
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
    
}
