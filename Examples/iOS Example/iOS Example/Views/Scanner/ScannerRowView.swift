//
//  ScannerRowView.swift
//  iOSDrinkOnKit Example
//
//  Created by Ben Wirz on 9/21/20.
//

import SwiftUI
import DrinkOnKit
import CoreBluetooth

// ScannedDrinkOnPeripheral Extension to Supply RSSI Image Name
extension ScannedDrinkOnPeripheral {
    
    // Returns the Image Name String associated with the current RSSI value
    var rssiImageName: String {
        
        // Trip points for each of the 1 to 5 RSSI signal strength bars
        let RSSI_CLOSE = -40.0   // the max value at close range
        let RSSI_FAR = -90.0     // the min value at max range
        let RSSI_STEP = (RSSI_FAR - RSSI_CLOSE) / 6
        
        guard let rssi = self.rssi else {
            return "RSSI"
        }
        if(rssi <= RSSI_FAR - RSSI_STEP) {
            return "RSSI1"
        } else if(rssi <= RSSI_FAR - 2 * RSSI_STEP) {
            return "RSSI2"
        } else if(rssi <= RSSI_FAR - 3 * RSSI_STEP) {
            return "RSSI3"
        } else if(rssi <= RSSI_FAR - 4 * RSSI_STEP) {
            return "RSSI4"
        } else {
            return "RSSI5"
        }
    }
}

struct ScannerRowView: View {
    
    @EnvironmentObject var appSharedData : AppSharedData
    
    @EnvironmentObject var scannedDrinkOnPeripheral: ScannedDrinkOnPeripheral
    
    // Function for connecting to the scanned peripheral
    func connectDrinkOn() {
        
        guard let peripheral : CBPeripheral = scannedDrinkOnPeripheral.peripheral else {
            return
        }
        appSharedData.scanning = false;
        DrinkOnKit.sharedInstance.connectPeripheral(peripheral)
    }
    
    // Function for disconnecting a connected peripheral
    func disconnectDrinkOn() {
        
        DrinkOnKit.sharedInstance.disconnectPeripheral()
    }
    
    
    var body: some View {
        HStack {
            Image(scannedDrinkOnPeripheral.rssiImageName)
                .frame(width: 32, height: 26)
            Text(scannedDrinkOnPeripheral.name)
            
            VStack {
                
                if let bottleLevel = scannedDrinkOnPeripheral.level {
                   Text(String(format: "Level %1.0f%%", bottleLevel * 100))
                }
                if let consumed = scannedDrinkOnPeripheral.consumed24hrs {
                   Text(String(format: "%1.1f Bottles", consumed))
                }
            }
            
            if scannedDrinkOnPeripheral.connected  {
                Text("Connected")
                //Button("Disconnect", action: disconnectDrinkOn)
            } else {
                Button("Connect", action: connectDrinkOn)
            }
            /*
            if scannedDrinkOnPeripheral.peripheral?.state == CBPeripheralState.disconnected {
                Button("Connect", action: connectDrinkOn)
            } else if scannedDrinkOnPeripheral.peripheral?.state == CBPeripheralState.connecting {
                Text("Connecting")
            } else if scannedDrinkOnPeripheral.peripheral?.state == CBPeripheralState.connected {
                
            }
 */
            Spacer()
        }

    }
}

struct ScannerRowView_Previews: PreviewProvider {

        
    static var previews: some View {
        
        Group {
            ScannerRowView().environmentObject(ScannedDrinkOnPeripheral())
        }
        .previewLayout(.fixed(width: 300, height: 70))
        
    }
}
