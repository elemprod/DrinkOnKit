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
   
    //@ObservedObject var drinkOnService : DrinkOnService = DrinkOnKit.sharedInstance.drinkOnPeripheral?.drinkOnService
    
    
    // Function for connecting to the scanned peripheral
    func connectDrinkOn() {
        
        appSharedData.scanning = false          // Stop Scanning
        
        guard let peripheral : CBPeripheral = scannedDrinkOnPeripheral.peripheral else {
            return
        }
        self.appSharedData.drinkOnKit.connectPeripheral(peripheral)
    }
    
    // Function for disconnecting a connected peripheral
    func disconnectDrinkOn() {
        
        appSharedData.drinkOnKit.disconnectPeripheral()
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
            if let drinkOnPeripheral : DrinkOnPeripheral = drinkOnKit.drinkOnPeripheral {
                Text("Peripheral")
                if let drinkOnService : DrinkOnService = drinkOnPeripheral.drinkOnService {
                    
                    Text("Bottle Level: ")
                    if let bottleLevel = drinkOnService.bottleLevel {
                        Text(String(bottleLevel))
                    }
                }
       
            }
            
            //Text("Bottle Level: " + String($appSharedData.bottleLevel))
         
            //drinkOnKit.drinkOnPeripheral.drinkOnService.bottleLevel.map {Text("Bottle Level: " + String($0))}
            
            //$appSharedData.bottleLevel.map {Text(String($0))}
            
            /*
            
            List {
                if let bottleLevel = $appSharedData.bottleLevel {
                    Text("Bottle Level: " + String(bottleLevel))
                }
            }
 */
            
            /*
            if let drinkOnService : DrinkOnService = $appSharedData.drinkOnService {
                Text("DrinkOn Service")
   
            }
 */
            
 /*
            if let drinkOnPeripheral : DrinkOnPeripheral = drinkOnKit.drinkOnPeripheral {
                Text("Peripheral")
       
            }
 
 */
            /*
            
            List {

                
                if let drinkOnService : DrinkOnService = drinkOnKit.drinkOnPeripheral?.drinkOnService? {
                    if let bottleLevel = drinkOnService.bottleLevel {
                        Text(String(bottleLevel))
                    }
                    if let levelSensor = drinkOnService.levelSensor {
                        Text(String(levelSensor))
                    }
                    if let consumed24hr = drinkOnService.consumed24hr {
                        Text(String(consumed24hr))
                    }
                    if let goal24hr = drinkOnKit.drinkOnService.goal24hr {
                        Text(String(goal24hr))
                    }
                    if let liquidLevelRaw = drinkOnService.liquidLevelRaw {
                        Text(String(liquidLevelRaw))
                    }
                    if let batteryLevel = drinkOnService.batteryLevel {
                        Text(String(batteryLevel))
                    }
                    if let runTime = drinkOnService.runTime {
                        Text(String(runTime))
                    }
                    if let firmwareVersion = drinkOnService.firmwareVersion {
                        Text(firmwareVersion)
                    }
                    if let dfuCode = drinkOnService.dfuCode {
                        Text(String(dfuCode))
                    }
                    if let modelCode = drinkOnService.modelCode {
                        Text(String(modelCode))
                    }
                    if let hardwareCode = drinkOnService.hardwareCode {
                        Text(String(hardwareCode))
                    }
                    if let UIStateCode = drinkOnService.UIStateCode {
                        Text(String(UIStateCode))
                    }
                }
                
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
