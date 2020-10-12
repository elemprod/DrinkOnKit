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
                    
                    NavigationLink(destination: DrinkOnPeripheralView(drinkOnPeripheral: peripheral.drinkOnPeripheral))
                        {
                        ScannerRowView(scannedDrinkOnPeripheral: peripheral)
                    }
                }
            
                Text(drinkOnKit.error.description)
                    .frame(alignment: .leading)
                Text(drinkOnKit.state.description)
                    .frame(alignment: .leading)
                
            }
            .navigationBarTitle("DrinkOn Scanner")
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
