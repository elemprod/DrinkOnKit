//
//  ScannerListData.swift
//  iOSDrinkOnKit Example
//
//  Observable Data Structure for the Scanner List
//
//  Created by Ben Wirz on 9/22/20.
//

import Foundation
import DrinkOnKit
import UIKit

final class AppSharedData: ObservableObject {

    /// Shared DrinkOn Kit
    var drinkOnKit : DrinkOnKit = DrinkOnKit.sharedInstance

    /// Connected DrinkOn Peripheral
    //@Published var drinkOnPeripheral : DrinkOnPeripheral? = DrinkOnKit.sharedInstance.drinkOnPeripheral

    /// Connected DrinkOn Peripheral DrinkOnService
    //@Published var drinkOnService : DrinkOnService? = DrinkOnKit.sharedInstance.drinkOnPeripheral?.drinkOnService
    
    //@Published var bottleLevel : Int = DrinkOnKit.sharedInstance.drinkOnPeripheral?.drinkOnService?.bottleLevel
    
    var cancellable = DrinkOnKit.sharedInstance.drinkOnPeripheral?.objectWillChange
        .sink { _ in
            print("** Peripheral " + DrinkOnKit.sharedInstance.drinkOnPeripheral.debugDescription)
    }
    
    /// Currently Scanning for DrinkOn Peripherals?
    @Published var scanning = false {  // currently scanning?
        didSet {
            print("Scanning DidSet: " + scanning.description)
            if(scanning) {
                drinkOnKit.scanForPeripherals(clearScannedPeripherals: true)
            } else {
                drinkOnKit.stopScanForPeripherals()
            }
        }
    }
    

    
    public init() {
        let notificationCenter = NotificationCenter.default
          notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
    }
    
    @objc func appMovedToBackground() {
        self.scanning = false   // Disable Scanning
    }
    
    
}
