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
    
    /// Currently Scanning for DrinkOn Peripherals?
    @Published var scanning = false {  // currently scanning?
        didSet {
            //print("Scanning DidSet: " + scanning.description)
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
