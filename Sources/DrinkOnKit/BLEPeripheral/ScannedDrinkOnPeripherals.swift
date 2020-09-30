import Foundation
import CoreBluetooth
/*!
 *  @class ScannedDrinkOnPeripherals
 *
 *  @discussion Storage container for a collection DrinkOn BLE Peripheral's which were detected during a BLE Scann.
 */
@available(iOS 13.0, *)
public class ScannedDrinkOnPeripherals: NSObject, ObservableObject {
    
    /// Array of DrinkOn Peripherals discovered during a BLE Scan.
    @Published public internal(set) var peripherals : [ScannedDrinkOnPeripheral] = []
    
    /**
     * Add a peripheral to the known peripherals array if not already in the array.
     *
     * If a ScannedPeripheral with a matching UUID already exists in the aray, return that peripheral.
     *
     * - parameter peripheral:          the peripheral to add
     * - returns:                       an existing or new ScannedPeripheral
     */
    internal func add(peripheral: CBPeripheral)->ScannedDrinkOnPeripheral {
        return add(peripheral: peripheral, RSSI: nil)
    }
    
    /**
     * Add a peripheral to the known peripherals array if not already in the array return the stored ScannedPeripheral
     *
     * If a ScannedPeripheral with a matching UUID already exists in the aray, update the RSSI and return that peripheral.
     *
     * - parameter peripheral:          the peripheral to add
     * - parameter andRSSI:             the RSSI
     * - returns:                       an existing or new ScannedPeripheral
     */
    internal func add(peripheral: CBPeripheral, RSSI: Double?)->ScannedDrinkOnPeripheral {
        
        guard let result = get(peripheral: peripheral) else {
            // Add the peripheral if not already in the array
            let newPeripheral = ScannedDrinkOnPeripheral(withPeripheral: peripheral, andRSSI: RSSI)
            peripherals.append(newPeripheral)
            return newPeripheral
        }
        if RSSI != nil {
            // update the RSSI
            peripherals[result.index].rssi = RSSI
        }
        return peripherals[result.index]
    }
    
    /// Function for adding an example peripheral to the peripherals
    public func exampleAdd() {
        let examplePeripheral = ScannedDrinkOnPeripheral()
        examplePeripheral.rssi = -40.0
        peripherals.append(examplePeripheral)
    }
    /**
     * Returns the peripheral with the matching UUID if known
     *
     * - parameter peripheral   : the peripheral to search for
     * - returns                    : the matching ScannedPeripheral or nil if not found
     */
    public func get(peripheral: CBPeripheral)->(peripheral: ScannedDrinkOnPeripheral, index: Int)? {
        for (index, element) in peripherals.enumerated() {
            guard let elementPeripheralID = element.peripheral?.identifier else {
                continue    // element peripheral empty, skip check
            }
            if elementPeripheralID == peripheral.identifier {
                return (element, index)
            }
        }
        return nil
    }
    
    /**
     * Search and return a peripheral with a matching UUID
     *
     * - parameter anScannedPeripheral: the peripheral to search for
     * - returns                    : the matching ScannedPeripheral or nil if not found and the index
     */
    public func get(peripheral: ScannedDrinkOnPeripheral)->(peripheral: ScannedDrinkOnPeripheral, index: Int)? {
        guard let peripheralID = peripheral.peripheral?.identifier  else {
            return nil  // Search Peripheral Empty
        }
        
        for (index, element) in peripherals.enumerated() {
            guard let elementPeripheralID = element.peripheral?.identifier else {
                continue    // element peripheral empty, skip check
            }
            if elementPeripheralID == peripheralID {
                return (element, index)
            }
        }
        return nil
    }
    
    /**
     * Remove a peripheral from the array searching by UUID
     *
     * - parameter anCBPeripheral: the peripheral to remove
     */
    internal func remove(peripheral: CBPeripheral) {
        guard let index = self.get(peripheral: peripheral)?.index else {
            return
        }
        peripherals.remove(at: index)
    }
    
    /**
     * Remove all of the peripherals from the peripherals array.
     *
     */
    internal func removeAll() {
        peripherals.removeAll()
    }
    
    /**
     *  Search for the scanned peripheral with the highest RSSI.
     * - returns: the peripheral with the highest RSSI or nil if no peripherals have been scanned
     */
    public func peripheralWithHighestRSSI() -> ScannedDrinkOnPeripheral? {
        
        if self.peripherals.count == 0 {
            return nil;
        }
        
        var strongestPeripheral : ScannedDrinkOnPeripheral! = nil;
        
        for aScannedPeripheral in peripherals {
            guard(strongestPeripheral != nil) else {
                strongestPeripheral = aScannedPeripheral;       // set the first scanned peripheral to the return peripheral
                continue;
            }
            
            guard let strongestPeripheralRSSI : Double = strongestPeripheral.rssi else {
                strongestPeripheral = aScannedPeripheral;       // previous strongest peripheral rssi was unset
                continue;
            }
            
            guard let aScannedPeripheralRSSI : Double = aScannedPeripheral.rssi else {
                continue;                                       // rssi unset
            }
            
            if(aScannedPeripheralRSSI > strongestPeripheralRSSI) {
                strongestPeripheral = aScannedPeripheral;   // current peripheral is the strongest
            }
            
        }
        return strongestPeripheral;
    }
    
}


