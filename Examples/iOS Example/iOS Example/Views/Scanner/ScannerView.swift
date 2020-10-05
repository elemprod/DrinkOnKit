//
//  ScannerView.swift
//  iOSDrinkOnKit Example
//
//  Created by Ben Wirz on 9/21/20.
//

import SwiftUI
import DrinkOnKit


struct ScannerView: View {
    
    @EnvironmentObject var appSharedData : AppSharedData
    
    @ObservedObject var scannedPeripherals : ScannedDrinkOnPeripherals = DrinkOnKit.sharedInstance.scannedDrinkOnPeripherals
    
    @ObservedObject var drinkOnKit :  DrinkOnKit = DrinkOnKit.sharedInstance
    

    var body: some View {
        NavigationView() {
            VStack {
                
                Toggle(isOn: $appSharedData.scanning) {
                    Text("Scan")
                }
                
                List(scannedPeripherals.peripherals) { peripheral in
                    
                    // Show the detail disclousre if connected
                    if peripheral.connected, let drinkOnPeripheral : DrinkOnPeripheral = DrinkOnKit.sharedInstance.drinkOnPeripheral {
                        NavigationLink(destination: DrinkOnPeripheralView()
                                        .environmentObject(drinkOnPeripheral)) {
                            ScannerRowView()
                                .environmentObject(peripheral)
                        }
                    } else {
                        ScannerRowView()
                            .environmentObject(appSharedData)
                            .environmentObject(peripheral)
                    }

                    /*
                    NavigationLink(destination: ConnectView()
                                    .environmentObject(peripheral)) {
                        ScannerRowView()
                            .environmentObject(peripheral)
                    }
                     */
                }
                
                
                
                Text(drinkOnKit.error.description)
                    .frame(alignment: .leading)
                Text(drinkOnKit.state.description)
                    .frame(alignment: .leading)
                
            }
            .navigationBarTitle(Text("DrinkOn Scanner"))
            .onDisappear() {
                appSharedData.scanning = false
            }
        }
        
    }
}

struct ScannerView_Previews: PreviewProvider {
    
    static var previews: some View {
        ScannerView().environmentObject(AppSharedData())
    }
    
}
