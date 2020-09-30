//
//  DrinkOnService.swift
//
//  Data Object for a DrinkOn BLE Service
//

import Foundation
import CoreBluetooth

/// DrinkOn BLE Service & Characteristic Identifiers
internal class DrinkOnServiceIdentifiers: NSObject {
    
    // DrinkOn Service Base UUID
    static let DrinkOnServiceUUIDString                             = "E5BA1000-B46E-7188-A34B-A74651E22E9D"
    static let DrinkOnServiceUUID                                   = CBUUID(string: DrinkOnServiceUUIDString)
    
    // DrinkOn Service Bottle Level Characteristic UUID
    static let DrinkOnServiceCharLevelUUIDString                    = "E5BA1001-B46E-7188-A34B-A74651E22E9D"
    static let DrinkOnServiceCharLevelUUID                          = CBUUID(string: DrinkOnServiceCharLevelUUIDString)
    
    // DrinkOn Service Liquid Consumption Goal Characteristic UUID
    static let DrinkOnServiceCharGoalUUIDString                    = "E5BA1002-B46E-7188-A34B-A74651E22E9D"
    static let DrinkOnServiceCharGoalUUID                          = CBUUID(string: DrinkOnServiceCharGoalUUIDString)
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
 * Used to protoect the device from too frequent BLE's accesses and characteristic validations.
 *
 * _Valid indicates the characteristic was discovered and is valid.
 * _ReadLocked indicates the Charactersitic was recently Read
 * _WriteLocked indicates a Characteristic Write is in progress.
 */
fileprivate struct DrinkOnServiceCharStatus: OptionSet {
    let rawValue: Int
    // Level Characteristic Status
    static let levelValid                       = DrinkOnServiceCharStatus(rawValue: 1 << 0)
    static let levelReadLocked                  = DrinkOnServiceCharStatus(rawValue: 1 << 1)
    
    // Goal Characteristic Status
    static let goalValid                        = DrinkOnServiceCharStatus(rawValue: 1 << 2)
    static let goalReadLocked                   = DrinkOnServiceCharStatus(rawValue: 1 << 3)
    static let goalWriteLocked                  = DrinkOnServiceCharStatus(rawValue: 1 << 4)
    
}


@available(iOS 13.0, *)
public class DrinkOnService: ObservableObject {
    
    /// The Bluetooth Peripheral for the service.
    public var peripheral : CBPeripheral {
        get {
            return service.peripheral
        }
    }
    
    /// The Service Delegate.
    public weak var delegate : DrinkOnServiceDelegate?
    
    internal var service                        : CBService
    fileprivate var levelCharacteristic         : CBCharacteristic?  = nil
    fileprivate var goalCharacteristic          : CBCharacteristic?  = nil
    
    /// Characteristic status flags
    fileprivate var characteristicStatus        : DrinkOnServiceCharStatus
    
    /// Has the Level Characteristic been validated?
    public var levelCharacteristicValid : Bool {
        get {
            return characteristicStatus.contains(.levelValid)
        }
    }
    
    /// Has the Goal Characteristic been validated?
    public var goalCharacteristicValid : Bool {
        get {
            return characteristicStatus.contains(.goalValid)
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
        characteristicStatus = []
        
        //TODO don't discover the characteristics until accessed to save BLE traffic??
        // Discover the Service Characteristics
        //let characteristics = [DrinkOnServiceIdentifiers.DrinkOnServiceCharLevelUUID, DrinkOnServiceIdentifiers.DrinkOnServiceCharGoalUUID]
        //service.peripheral.discoverCharacteristics(characteristics, for: service)
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
            case DrinkOnServiceIdentifiers.DrinkOnServiceCharLevelUUID:
                //TODO
                print("Level Characteristic Discovered")
                
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







