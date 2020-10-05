//
//  DrinkOnPeripheralView.swift
//  
//
//  Created by Ben Wirz on 10/5/20.
//

import SwiftUI
import DrinkOnKit

struct DrinkOnPeripheralView: View {
    
    @EnvironmentObject var drinkOnPeripheral : DrinkOnPeripheral
    
    /// Conditionally display a view with an optional value
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
    
    var body: some View {
        
        NavigationView() {
            VStack {
                
                if drinkOnPeripheral.connected  {
                    Text("Connected")
                } else {
                    Text("Disconnected")
                }
                Spacer()
                    .frame(height: 10)
                
                /*
                Unwrap($drinkOnPeripheral.levelSensor) { levelSensor in
                    Text("Level Sensor: " + String(levelSensor) + "Cnts")
                }
                
                Unwrap(drinkOnPeripheral.consumed24hr) { consumed24hr in
                    Text("Consumed: " + String(consumed24hr) + " Bottles")
                }
                
                Unwrap(drinkOnPeripheral.goal24hr) { goal24hr in
                    Text("Goal: " + String(goal24hr) + "Bottles")
                }
                
                Unwrap(drinkOnPeripheral.batteryLevel) { batteryLevel in
                    Text("Battery: " + String(batteryLevel) + "%")
                }
                 
                      
                Unwrap(drinkOnPeripheral.runTime) { runTime in
                    Text("Run Time: " + String(runTime) + "hrs")
                }
                
                Unwrap(drinkOnPeripheral.firmwareVersion) { firmwareVersion in
                    Text("Firmware Ver: " + firmwareVersion)
                }
                
                Unwrap(drinkOnPeripheral.dfuCode) { dfuCode in
                    Text("DFU Code: " + String(dfuCode))
                }
                
                Unwrap(drinkOnPeripheral.hardwareCode) { hardwareCode in
                    Text("Hardware: " + hardwareCode)
                }
                */
                
                Unwrap(drinkOnPeripheral.UIStateCode) { stateCode in
                    Text("State Code: " + String(stateCode))
                    Spacer()
                        .frame(height: 10)
                }
        
                
                Unwrap(drinkOnPeripheral.modelCode) { modelCode in
                    Text("Model: " + String(modelCode))
                    Spacer()
                        .frame(height: 10)
                }
    
                
            }

        }
        .navigationBarTitle(Text("DrinkOn Peripheral"))
        .onDisappear() {
            DrinkOnKit.sharedInstance.disconnectPeripheral()
        }

    }
}

/*
struct DrinkOnPeripheralView_Previews: PreviewProvider {
    static var previews: some View {
        DrinkOnPeripheralView()
    }
}
*/
