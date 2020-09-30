//
//  CentralManager.swift
//
//
//  Manages Bluetooth Connectivity for DrinkOn Periepherals
//
//

import Foundation
import CoreBluetooth

/**
 * Central Manager Delegate.
 *
 */
@available(iOS 13.0, *)
internal protocol CentralManagerDelegate: class {
    /**
     * The Central Manager detected the Bluetooth power state.
     *
     * - Parameter manager          : The Central Manager.
     * - poweredOn                    : Bluetooth is powered on.
     */
    func centralManager(_ manager: CentralManager, didUpdateBluetoothPower poweredOn: Bool)
    
    /**
     * The Central Manager updated the devices Bluetooth support state.
     *
     * - Parameter manager          : The Central Manager.
     * - bluetoothSupported         : Bluetooth is supported.
     */
    func centralManager(_ manager: CentralManager, didUpdateBluetoothSupport bluetoothSupported: Bool)
    
    /**
     * The Central Manager updated the devices Bluetooth authorization state.
     *
     * - Parameter manager          : The Central Manager.
     * - bluetoothAuthorized        : Bluetooth is authorized.
     */
    func centralManager(_ manager: CentralManager, didUpdateBluetoothAuthorization bluetoothAuthorized: Bool)
    
    /**
     * The Central Manager failed to connect to a peripheral.
     *
     * - Parameter manager              : The Central Manager.
     * - Parameter peripheral           : The peripheral.
     */
    func centralManager(_ manager: CentralManager, didFailToConnect peripheral: CBPeripheral)
    
    /**
     * The Central Manager disconnected from a DrinkOn Peripheral.
     *
     * - Parameter manager              : The Central Manager.
     * - Parameter peripheral           : The peripheral.
     */
    func centralManager(_ manager: CentralManager, didDisconnect peripheral: CBPeripheral)
    
    /**
     * The Central Manager connected to a Peripheral.
     *
     * - Parameter manager              : The Central Manager.
     * - Parameter peripheral           : The peripheral.
     */
    func centralManager(_ manager: CentralManager, didConnect peripheral: DrinkOnPeripheral)
    
}

@available(iOS 13.0, *)
internal class CentralManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    
    //MARK: - Delegate Properties
    internal weak var delegate : CentralManagerDelegate?
    
    //MARK: - Singleton Accessor
    internal static let sharedInstance = CentralManager()
    
    /// The DrinkOn Peripherals discovered during the BLE Scan
    @Published internal var scannedPeripherals : ScannedDrinkOnPeripherals = ScannedDrinkOnPeripherals()
    
    /// The selected peripheral to attempt to connect with.
    fileprivate var selectedPeripheral : CBPeripheral? = nil
    
    /// The current DrinkOnPeripheral.
    @Published internal var drinkOnPeripheral : DrinkOnPeripheral? = nil
    
    /// BLE central manager, implicity unwrap it since its set in init
    fileprivate var centralManager : CBCentralManager!
    fileprivate let centralQueue = DispatchQueue(label: "com.elementinc.drinkonkit", attributes: [])
    
    private override init() {
        super.init()        // call so self is initialized prior to the centeral manager
        centralManager = CBCentralManager(delegate: self, queue: centralQueue)
    }
    
    
    //MARK:  BLE Scanner
    
    /**
     * Starts scanning for peripherals
     * - Parameter clearList:  Clear the list of previously scanned DrinkOn's?
     * - returns: an array of known peripherals or empty if the central manager is powered off or BLE is unavailable
     */
    internal func scanForPeripherals() {
        
        if centralManager.isScanning {  // restart scanning if previously scanning
            stopScanning()
        }
        
        // Allow duplicate keys - enables calls back even for known peripherals which is required to get the updated advertisement contents and update RSSI
        let options: NSDictionary = NSDictionary(objects: [NSNumber(value: true as Bool)], forKeys: [CBCentralManagerScanOptionAllowDuplicatesKey as NSCopying])
        
        // Start scanning for devices which advertise the DrinkOn Service UUID
        centralManager.scanForPeripherals(withServices: [DrinkOnServiceIdentifiers.DrinkOnServiceUUID], options: options as? [String : AnyObject])
        
        print("Scanning Started")
    }
    
    /// Stop scanning for peripherals
    internal func stopScanning() {
        centralManager.stopScan()
        print("Stopped Scanning")
    }
    
    
    /**
     * Is Bluetotooth powered on and authorzied?
     * - returns: true if the devices Bluetooth is turned on and authorzied.
     */
    internal var blePoweredOn : Bool {
        return centralManager.state == .poweredOn
    }
    
    
    /**
     * Attempt to connect to a peripheral.
     *
     * If the peripheral is already connected, calls the delegate didConnect method.
     * If the periperal is already attempting to connnect, the function just returns.
     *
     * - parameter aPeripheral:         The peripheral to connect.
     *
     */
    internal func connectPeripheral(_ peripheral: CBPeripheral) {
        
        self.selectedPeripheral = peripheral    // Store peripheral reference
        print("Connecting to: \(peripheral)")
        centralManager.connect(peripheral, options: nil)
        
        /*
         if peripheral.state == .connected {                                 // the peripheral is already connected
         print("connectPeripheral - Peripheral Already Connected")
         
         if peripheral === self.drinkOnPeripheral?.peripheral {
         // The peripheral matches the previously connected DrinkOn
         if(
         }
         let connectedPeripheral = DrinkOn
         // make the callback before starting discovery so delegate has a chance to register itself as a delegate
         self.delegate?.centralManager(self, didConnect: connectedPeripheral)
         connectedPeripheral.startServiceDiscovery()
         return
         } else if peripheral.state == .connecting {                         // already attempting to connect to the peripheral
         print("connectPeripheral - Already Attempting to Connect to Peripheral")
         } else {
         print("Connecting to: \(peripheral)")
         centralManager.connect(peripheral, options: nil)
         }
         */
    }
    
    /**
     * Dissconnect from a peripheral
     *
     * - parameter peripheral:          The peripheral to disconnect.
     * - return:                        Returns true if the connection process was started.
     *                                  False if the peripheral is already disconnected or BLE is powered off.
     */
    internal func disconnectPeripheral(peripheral: DrinkOnPeripheral) -> Bool {
        guard centralManager.state == .poweredOn else {
            print("Power Off")
            return false
        }
        
        if (peripheral.peripheral.state == .connected) {
            centralManager.cancelPeripheralConnection(peripheral.peripheral)
            return true
        } else {
            print("Not Connected")
            return false
        }
    }
    
    //MARK:  CBCentralManagerDelgate
    
    /// The power or authorization state of the central manager changed
    internal func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        switch central.state {
        case .poweredOff :
            print("Bluetooth is Powered Off")
            delegate?.centralManager(self, didUpdateBluetoothPower: false)
            return
        case .poweredOn:
            print("Bluetooth Powered On")
            delegate?.centralManager(self, didUpdateBluetoothPower: true)
            delegate?.centralManager(self, didUpdateBluetoothSupport: true)
            delegate?.centralManager(self, didUpdateBluetoothAuthorization: true)
            
        case .resetting:
            print("Bluetooth Resetting")
            delegate?.centralManager(self, didUpdateBluetoothPower: false)
            return
        case .unauthorized:
            print("Bluetooth not authorized on this device")
            delegate?.centralManager(self, didUpdateBluetoothAuthorization: false)
            return
        case .unknown :
            print("Bluetooth Power State Unknown")
            return
        case .unsupported:
            print("Bluetooth not supported on this device")
            delegate?.centralManager(self, didUpdateBluetoothSupport: false)
            return
        default:
            print("Unknown State")
            return
        }
    }
    
    //TODO - Move this to seperate advertising class???
    /// Function for processing advertising data and updating the ScannedPeripheral
    internal func advertisementProcess(peripheral : ScannedDrinkOnPeripheral, advertisementData: [String : Any]) {
        
        let elementManufacturerID : UInt16 = 0x070B     // Element Products Company ID assigned by the BLE SIG
        
        let advertLevelTypeID : UInt8 = 0x11            // Manufacturer Specific Level Advertisement Type ID
        let advertLevelLen = 5                          // Length of the Level Advertisement
        
        // Extract the Manufacturing Data
        if let manufacturerData = advertisementData["kCBAdvDataManufacturerData"] as? Data {
            //print("Man Data: " + manufacturerData.description)
            if(manufacturerData.count >= 3) {   // Error check the minimum manufacturer specific advertisement data length
                // Construct 2-byte manufacturer ID data (little endian)
                let manufactureId = UInt16(manufacturerData[0]) + UInt16(manufacturerData[1]) << 8
                if(manufactureId == elementManufacturerID) {    // Check the manufacturer ID
                    //print(String(format: "Man Id: 0x%04X", manufactureId))
                    let advertTypeId = UInt8(manufacturerData[2])
                    //print(String(format: "Advert Typ Id: 0x%02X", advertTypeId))
                    if(advertTypeId == advertLevelTypeID && manufacturerData.count == advertLevelLen) {
                        // Level Advertisement
                        let levelRaw = Int8(bitPattern: manufacturerData[3])
                        let consumed24hrsRaw = Int8(bitPattern: manufacturerData[4])
                        
                        if(levelRaw >= 0 && consumed24hrsRaw >= 0) {
                            // convert to percentage
                            var newLevel = Double(levelRaw) * 0.01
                            if(newLevel > 1.0) {
                                newLevel = 1.0
                            }
                            peripheral.level = newLevel
                            peripheral.consumed24hrs = Double(consumed24hrsRaw) * 0.1
                            print(String(format: "Advert Level %1.0f%%, Consumed %1.1f Bottles", peripheral.level! * 100, peripheral.consumed24hrs!))
                        } else {
                            // Error
                            peripheral.level = nil
                            print("Advert Level Error Code: " + levelRaw.description)
                        }
                    } else {
                        print("Unrecognized Advertisement Format")
                    }
                }
            }
            
        }
    }
    
    /// Central Manager Scanner Callback for devices discovered during a BLE Scan.
    internal func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        if let result = scannedPeripherals.get(peripheral: peripheral) {
            // update the RSSI if the peripheral was previsously detected
            DispatchQueue.main.async {
                result.peripheral.rssi = RSSI.doubleValue
                self.advertisementProcess(peripheral: result.peripheral, advertisementData: advertisementData)
            }
        } else {
            DispatchQueue.main.async {
                let newPeripheral = self.scannedPeripherals.add(peripheral: peripheral, RSSI: RSSI.doubleValue)  // add the new peripheral
                self.advertisementProcess(peripheral: newPeripheral, advertisementData: advertisementData)
            }
            print("New DrinkOn Discovered")
        }
    }
    
    
    internal func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        
        if let name = peripheral.name {
            print("Connected to: \(name).")
        } else {
            print("Connected to device.")
        }
        
        // Check if connected to the Selected Peripheral
        if(peripheral === self.selectedPeripheral) {
            
            if self.drinkOnPeripheral?.peripheral != nil && peripheral === self.drinkOnPeripheral?.peripheral {
                //The connected Peripheral is the same as the previously connected DrinkOn Peripheral
                if self.drinkOnPeripheral?.drinkOnService == nil {
                    // Only need to start Service Discovery if Service has not previously been discovered
                    self.drinkOnPeripheral!.startServiceDiscovery()
                }
            } else {
                // Create new DrinkOnPeripheral from the connected Peripheral
                self.drinkOnPeripheral = DrinkOnPeripheral(withPeripheral: peripheral)
                self.drinkOnPeripheral!.startServiceDiscovery()                     // Start Service Discovery
            }
            delegate?.centralManager(self, didConnect: self.drinkOnPeripheral!)
        }
    }
    
    internal func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Centeral Manager didFailToConnect")
        print("Error: \(String(describing: error))")
        
        if(peripheral === self.selectedPeripheral) {
            delegate?.centralManager(self, didFailToConnect: peripheral)
        }
    }
    
    /*
     
     func centralManager(_ central: CBCentralManager, willRestoreState dict: [String : Any]) {
     //TODO - need implementation
     print("will restore state")
     }
     */
    
    internal func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        
        if error != nil {
            print("Centeral Manager didDisconnectPeripheral Error: \(String(describing: error))")
        } else {
            print("Centeral Manager didDisconnectPeripheral")
        }
        
        if(peripheral === self.selectedPeripheral) {
            delegate?.centralManager(self, didDisconnect: peripheral)
        }
    }
}




