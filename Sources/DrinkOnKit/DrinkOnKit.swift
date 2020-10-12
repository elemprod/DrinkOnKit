//
//  DrinkOnKit.swift
//  DrinkOnKit
//
//  Created by Ben Wirz on 9/16/20.
//

import Foundation
import CoreBluetooth


/// DrinkOnKit Error Definition
public enum DrinkOnKitError : Int {
    case none                                               // No error
    case bluetoothUnsupported                               // Bluetooth Low Energy is not supported by the device.
    case bluetoothPoweredOff                                // Bluetooth is powered off on the device.
    case bluetoothUnauthorized                              // Bluetooth is not authorized on the device.
    case busyScanning                                       // Already scanning for DrinkOn Perpherials
    case busyConnecting                                     // Already attempting to connect to a DrinkOn Perpherial
    case busyConnected                                      // Already connected to a DrinkOn Perpherial
    case noPerpherialsFound                                 // No DrinkOn Perpherials were found
    case connectionFailed                                   // Connecting to the DrinkOn Perpherial failed.
    case internalError                                      // Internal error
    
    public var description: String {
        switch self {
        case .none:
            return NSLocalizedString("No Errors.", comment: "DrinkOnKitError.noError")
        case .bluetoothUnsupported:
            return NSLocalizedString("Bluetooth not supported by this device.", comment: "DrinkOnKitError.deviceBLEUnsupported")
        case .bluetoothPoweredOff:
            return NSLocalizedString("Bluetooth is powered off.", comment: "DrinkOnKitError.deviceBLEPoweredOff")
        case .bluetoothUnauthorized:
            return NSLocalizedString("Bluetooth is not authorized.", comment: "DrinkOnKitError.deviceBLEUnauthorized")
        case .busyScanning:
            return NSLocalizedString("Already scanning for DrinkOn Perpherials.", comment: "DrinkOnKitError.busyScanning")
        case .busyConnecting:
            return NSLocalizedString("Already attempting to connect to a DrinkOn Perpherial..", comment: "DrinkOnKitError.busyConnecting")
        case .busyConnected:
            return NSLocalizedString("Already connected to a DrinkOn Perpherial.", comment: "DrinkOnKitError.busyConnected")
        case .noPerpherialsFound:
            return NSLocalizedString("No DrinkOn Perpherials were found.", comment: "DrinkOnKitError.noPerpherialsFound")
        case .connectionFailed:
            return NSLocalizedString("Connection Failed.", comment: "DrinkOnKitError.connectionFailed")
        case .internalError:
            return NSLocalizedString("Internal Error.", comment: "DrinkOnKitError.internalError")
            
        }
    }
}

/// DrinkOnKit State Definition
public enum DrinkOnKitState : Int {
    case unknown                                            // Unknown State
    case ready                                              // Initialized and ready to be used
    case scanning                                           // Scanning for DrinkOn Perpherials
    case connecting                                         // Attempting to Connect to a DrinkOn Perpherial
    case connected                                          // Connected to a DrinkOn Perpherial
    case bluetoothPoweredOff                                // Bluetooth is Powered Off
    case bluetoothUnauthorized                              // Bluetooth access has not been Authorized on this Device
    case bluetoothUnsupported                               // Bluetooth is not supported on this Device
    
    public var description: String {
        switch self {
        case .unknown:
            return NSLocalizedString("Undefined State.", comment: "DrinkOnKitState.unknown")
        case .ready:
            return NSLocalizedString("Ready", comment: "DrinkOnKitState.ready")
        case .scanning:
            return NSLocalizedString("Scanning.", comment: "DrinkOnKitState.scanning")
        case .connecting:
            return NSLocalizedString("Attempting Connection.", comment: "DrinkOnKitState.connecting")
        case .connected:
            return NSLocalizedString("Connected.", comment: "DrinkOnKitState.connected")
        case .bluetoothPoweredOff:
            return NSLocalizedString("Bluetooth is Powered Off.", comment: "DrinkOnKitState.bluetoothPoweredOff")
        case .bluetoothUnauthorized:
            return NSLocalizedString("Bluetooth has not been Authorized on this Device.", comment: "DrinkOnKitState.bluetoothUnauthorized")
        case .bluetoothUnsupported:
            return NSLocalizedString("Bluetooth is not supported on this Device.", comment: "DrinkOnKitState.bluetoothUnsupported")
        }
    }
}




/// DrinkOnKit Delegate
@available(iOS 13.0, *)
public protocol DrinkOnKitDelegate: class {
    
    /**
     * Connected to a DrinkOnPeripheral
     *
     * - Parameter drinkOnKit:              The DrinkOnKit.
     * - Parameter drinkOnPeriperal:        The Connected Peripheral
     */
    func drinkOnKit(_ drinkOnKit: DrinkOnKit, didConnect : DrinkOnPeripheral)
}


/*
 * A high level Library Module for acessing DrinkOn Peripherals via Bluetooth Low Energy
 *
 * The Module Supports:
 *
 *
 * Scanning for DrinkOn Peripherals
 *  Decoding Advertised Data
 *
 * Connecting to DrinkOn Peripherals
 *
 *
 * Note that the library can only be in one of the DrinkOnKitState states at time which imposes the following limiations.
 * The library can either scan for peripherals or connect to a peripheral but not both at the same time.
 * The library can only connect to a single DrinkOn Peripheral at a time.
 *
 *
 * User Application Requirements
 *
 * The application's info.plist must include NSBluetoothAlwaysUsageDescription and NSBluetoothPeripheralUsageDescription.
 *
 * An application should typically stop scanning and disconnect from a connected peripheral when it moves to the background state.
 *
 */


@available(iOS 13.0, *)
@objc public class DrinkOnKit: NSObject, ObservableObject, CentralManagerDelegate
{
    //MARK: - Singleton Accessor
    
    /// Shared Instance
    public static let sharedInstance = DrinkOnKit()
    
    /// DrinkOnKit Delegate
    public weak var delegate : DrinkOnKitDelegate?
    
    /// The public library state.  Published on the main thread on stateInternal change.
    @Published public var state : DrinkOnKitState = DrinkOnKitState.unknown
    
    /// The internal library state.
    private var stateInternal : DrinkOnKitState = DrinkOnKitState.unknown {
        willSet(newState) {
            if stateInternal != newState {
                DispatchQueue.main.async {
                    //print("State: " + newState.description)
                    self.state = newState   // Publish a new state from the main thread
                }
            }
        }
    }
    
    /// The current public library error.  Published on the main thread on errorInternal change.
    @Published public var error : DrinkOnKitError = DrinkOnKitError.none
    
    /// The internal library error.
    private var errorInternal : DrinkOnKitError = DrinkOnKitError.none {
        willSet(newError) {
            if errorInternal != newError {
                DispatchQueue.main.async {
                    self.error = newError   // Publish a new error from the main thread
                }
            }
        }
    }
    
    
    
    //MARK: - Initializer
    private override init() {
        super.init()
        self.state = DrinkOnKitState.ready
        self.stateInternal = DrinkOnKitState.ready
        CentralManager.sharedInstance.delegate = self
    }
    
    /// Function for checking the BLE Hardware for Accessiblity
    /// Updates error code and if the BLE hardware is not in an accessible state and returns false
    /// Clears any previous Errors and Returns true if the BLE hardware is ready to be used
    private func bleAccessCheck() -> Bool {
        
        switch self.stateInternal {
        case .unknown:
            errorInternal = .internalError
        case .ready:
            errorInternal = .none
            return true
        case .scanning:
            errorInternal = .busyScanning
        case .connecting:
            errorInternal = .busyConnecting
        case .connected:
            errorInternal = .busyConnected
        case .bluetoothPoweredOff:
            errorInternal = .bluetoothPoweredOff
        case .bluetoothUnauthorized:
            errorInternal = .bluetoothUnauthorized
        case .bluetoothUnsupported:
            errorInternal = .bluetoothUnsupported
        }
        return false
    }
    
    //MARK: - Scanning Functions
    
    /// The DrinkOn Peripherals discovered during a Scan.
    @Published public var scannedDrinkOnPeripherals : ScannedDrinkOnPeripherals = CentralManager.sharedInstance.scannedPeripherals
    
    /** Function for starting BLE scanning
     *
     * - Parameter clearScannedPeripherals:  Clear the list of previously scanned DrinkOn Peripherals?
     */
    public func scanForPeripherals(clearScannedPeripherals : Bool) {
        
        if(clearScannedPeripherals) {
            self.scannedDrinkOnPeripherals.removeAll()
        }
        if(bleAccessCheck()) {           // Start Scanning
            stateInternal = .scanning
            CentralManager.sharedInstance.scanForPeripherals()
        }
    }
    
    /// Function for stopping BLE scanning
    public func stopScanForPeripherals() {
        CentralManager.sharedInstance.stopScanning()
        
        if(self.stateInternal == .scanning) {
            self.stateInternal = .ready         // clear the scanning state
        }
        if(self.error == .busyScanning || self.error == .busyConnecting || self.error == .busyConnected) {
            self.errorInternal = .none
        }
    }
    
    //MARK: - Connection Functions
    
    /// The current DrinkOnPeripheral.
    /// Set on the first connection with a DrinkOn Peripheral.  Remains valid even after disconnect
    //@Published public var drinkOnPeripheral : DrinkOnPeripheral?
    
    // The maximum duration to attempt to connect to a peripheral before cancelling the attempt. (seconds)
    fileprivate let ConnectionTimeOut: Double = 4.0
    
    /**
     * Function for attempting  to connect to a DrinkOn BLE Peripheral.
     *
     * Note that only one DrinkOn peripheral can be connected to at a time.
     * If the device is already connected to a peripheral, a busyConnected error is reported.
     * If the periperal is already attempting to connnect a peripheral, a busyConnecting error is reported.
     * If BLE is inaccessible, the matching error will be reported.
     *
     * - parameter peripheral:          The peripheral to connect.
     * - parameter options:             The peripheral connection options.
     *
     */
    public func connectPeripheral(_ peripheral: DrinkOnPeripheral) {
        if(self.bleAccessCheck()) {               // Attempt Connection
            stateInternal = .connecting
            print("Connecting to: \(peripheral.debugDescription)")
            CentralManager.sharedInstance.connectPeripheral(peripheral)
            
            DispatchQueue.main.async {
                //self.drinkOnPeripheral = peripheral
                peripheral.state = peripheral.peripheral.state
            }
            
            // Check if the connection attempt was sucessful after a delay.
            //TODO would be better to use a timer that can be invalidated
            // the peripheral could connect, disconnect and the attempt another connection before the timer expires
            delay(self.ConnectionTimeOut, closure: {
                // Still attempting to connect, clear the state and publish error
                if(self.stateInternal == .connecting) {
                    self.stateInternal = .ready
                    self.errorInternal = .connectionFailed
                    //TODO should we call cancelPeripheralConnection???
                }
            })
        }
    }
    
    /// Function for disconnecting a connected peripheral
    public func disconnectPeripheral(_ peripheral: DrinkOnPeripheral) {
        
        _ = CentralManager.sharedInstance.disconnectPeripheral(peripheral)
    }
    
    //MARK:  CentralManagerDelegate
    internal func centralManager(_ manager: CentralManager, didUpdateBluetoothPower poweredOn: Bool) {
        
        if poweredOn {
            if(self.stateInternal == .bluetoothPoweredOff || self.stateInternal == .unknown) {
                self.stateInternal = .ready         // clear the powered off state
            }
            if(self.error == .bluetoothPoweredOff) {
                self.errorInternal = .none         // clear the powered off error
            }
            
        }else {
            self.stateInternal = .bluetoothPoweredOff
        }
    }
    
    internal func centralManager(_ manager: CentralManager, didUpdateBluetoothSupport bluetoothSupported: Bool) {
        if !bluetoothSupported {
            stateInternal = .bluetoothUnsupported     // will never change to supported once set to unsupported
            errorInternal = .bluetoothUnsupported
        }
    }
    
    internal func centralManager(_ manager: CentralManager, didUpdateBluetoothAuthorization bluetoothAuthorized: Bool) {
        
        if bluetoothAuthorized {
            if(self.stateInternal == .bluetoothUnauthorized) {
                self.stateInternal = .ready         // clear the unauthorized off state
            }
            if(self.error == .bluetoothUnauthorized) {
                self.errorInternal = .none         // clear the unauthorized error
            }
        } else {
            stateInternal = .bluetoothUnauthorized
        }
    }
    
    internal func centralManager(_ manager: CentralManager, didFailToConnect peripheral: DrinkOnPeripheral) {
        if(self.stateInternal == .connecting || self.stateInternal == .connected) {
            self.stateInternal = .ready         // clear the connecting / connected states
        }
        self.errorInternal = .connectionFailed
        DispatchQueue.main.async {
            if let scannedDrinkOnPeripheral = self.scannedDrinkOnPeripherals.get(peripheral: peripheral.peripheral) {
                scannedDrinkOnPeripheral.peripheral.connected = false;   // Update the matching scanned peripheral connection state
            }
            peripheral.state = peripheral.peripheral.state
        }
    }
    
    internal func centralManager(_ manager: CentralManager, didDisconnect peripheral: DrinkOnPeripheral) {
        print("Did Disconnect: \(peripheral.debugDescription)")
        if(self.stateInternal == .connecting || self.stateInternal == .connected) {
            self.stateInternal = .ready         // clear the connecting / connected states
        }
        if(self.error == .busyScanning || self.error == .busyConnecting || self.error == .busyConnected) {
            self.errorInternal = .none
        }
        DispatchQueue.main.async {
            if let scannedDrinkOnPeripheral = self.scannedDrinkOnPeripherals.get(peripheral: peripheral.peripheral) {
                scannedDrinkOnPeripheral.peripheral.connected = false;   // Update the matching scanned peripheral connection state
            }
            peripheral.state = peripheral.peripheral.state
        }
    }
    
    internal func centralManager(_ manager: CentralManager, didConnect peripheral: DrinkOnPeripheral) {
        stateInternal = .connected
        errorInternal = .none
        print("Did Connect: \(peripheral.debugDescription)")
        
        DispatchQueue.main.async {
            if let scannedDrinkOnPeripheral = self.scannedDrinkOnPeripherals.get(peripheral: peripheral.peripheral) {
                scannedDrinkOnPeripheral.peripheral.connected = true;   // Update the matching scanned peripheral connection state
            }
            peripheral.state = peripheral.peripheral.state
            self.delegate?.drinkOnKit(self, didConnect: peripheral)
        }

    }

}

