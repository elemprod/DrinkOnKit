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
    
    struct Unwrap<Value, Content: View>: View {
        private let value: Value?
        private let contentProvider: (Value) -> Content

        init(_ value: Value?,
             @ViewBuilder content: @escaping (Value) -> Content) {
            self.value = value
            self.contentProvider = content
        }

        var body: some View {
            value.map(contentProvider)
        }
    }
    
    @EnvironmentObject var scannedDrinkOnPeripheral: ScannedDrinkOnPeripheral

    @ObservedObject var drinkOnKit :  DrinkOnKit = DrinkOnKit.sharedInstance

    //@ObservedObject var drinkOnKitState :  DrinkOnKitState = DrinkOnKit.sharedInstance.state
    
    /*
    
    var cancellable = DrinkOnKit.sharedInstance.state.
        .sink { _ in
            DispatchQueue.main.async {
                if let drinkOnPeripheral : DrinkOnPeripheral = DrinkOnKit.sharedInstance.drinkOnPeripheral {
                    DrinkOnPeripheralView(drinkOnPeripheral: drinkOnPeripheral)
                }
            }
            
            /*
            print("**** Peripheral " + DrinkOnKit.sharedInstance.drinkOnPeripheral.debugDescription)
             */
    }
*/
    
    // Function for connecting to the scanned peripheral
    func connectDrinkOn() {
        
        guard let peripheral : CBPeripheral = scannedDrinkOnPeripheral.peripheral else {
            return
        }
        self.drinkOnKit.connectPeripheral(peripheral)
    }
    
    // Function for disconnecting a connected peripheral
    func disconnectDrinkOn() {
        
        self.drinkOnKit.disconnectPeripheral()
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
            
            Unwrap(drinkOnKit.drinkOnPeripheral) { drinkOnPeripheral in
                Text("Peripheral")
            }
            
            
            /*
            Unwrap(drinkOnKit.drinkOnPeripheral.bottleLevel) { bottleLevel in

                Text("Bottle Level: " + String(bottleLevel) + "%")
            }
            
            */
            /*
            Unwrap(drinkOnKit.drinkOnPeripheral) { drinkOnPeripheral in
                DrinkOnPeripheralView(drinkOnPeripheral)
            }
            */
            
            /*
            if let drinkOnPeripheral : DrinkOnPeripheral = drinkOnKit.drinkOnPeripheral {
                DrinkOnPeripheralView(drinkOnPeripheral)
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
