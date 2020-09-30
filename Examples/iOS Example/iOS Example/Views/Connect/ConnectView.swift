//
//  ConnectView.swift
//  iOSDrinkOnKit Example
//
//  Created by Ben Wirz on 9/28/20.
//

import SwiftUI
import DrinkOnKit
import CoreBluetooth


struct ConnectView: View {
    
    @EnvironmentObject var appSharedData : AppSharedData
    
    @EnvironmentObject var scannedDrinkOnPeripheral: ScannedDrinkOnPeripheral

    @ObservedObject var drinkOnKit :  DrinkOnKit = DrinkOnKit.sharedInstance
    
    // Function for connecting to the scanned peripheral
    func connectDrinkOn() {
        
        appSharedData.scanning = false          // Stop Scanning
        
        guard let peripheral : CBPeripheral = scannedDrinkOnPeripheral.peripheral else {
            return
        }
        self.drinkOnKit.connectPeripheral(peripheral)
    }
    
    // Function for disconnecting a connected peripheral
    func disconnectDrinkOn() {
        
        DrinkOnKit.sharedInstance.disconnectPeripheral()
    }
    
    var body: some View {

        VStack {
            
            if scannedDrinkOnPeripheral.peripheral?.state == CBPeripheralState.disconnected {
                Button("Connect", action: connectDrinkOn)
            } else if scannedDrinkOnPeripheral.peripheral?.state == CBPeripheralState.connecting {
                Text("Connecting")
            } else if scannedDrinkOnPeripheral.peripheral?.state == CBPeripheralState.connected {
                Button("Disconnect", action: disconnectDrinkOn)
            }
            
            
            /*
            if let deviceName = drinkOnPeripheral.peripheral.name {
               Text(deviceName)
            }
            */
            
        }.onDisappear() {
            self.disconnectDrinkOn()
        }
        
    }
}

struct ConnectView_Previews: PreviewProvider {
    static var previews: some View {
        ConnectView()
    }
}
