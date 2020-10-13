//
//  DrinkOnPeripheralView.swift
//  
//
//  Created by Ben Wirz on 10/5/20.
//

import SwiftUI
import DrinkOnKit
import CoreBluetooth

struct DrinkOnPeripheralView: View {
    
    @ObservedObject var drinkOnPeripheral : DrinkOnPeripheral
    
    @ObservedObject var drinkOnKit :  DrinkOnKit = DrinkOnKit.sharedInstance
    
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
        
        VStack {
            List {
                Unwrap(self.drinkOnPeripheral.statusCharacteristic) { statusCharData in
                    StatusCharacteristicView(characteristicData: statusCharData)
                }
                
                Unwrap(drinkOnPeripheral.infoCharacteristic) { infoCharData in
                    InfoCharacteristicView(characteristicData: infoCharData)
                }
                
                Unwrap(drinkOnPeripheral.levelSensorCharacteristic) { levelSensorCharData in
                    LevelSensorCharacteristicView(drinkOnPeripheral: drinkOnPeripheral, characteristicData: levelSensorCharData)
                }
                
                Unwrap(drinkOnPeripheral.logCharacteristic) { logCharData in
                    LogCharacteristicView(characteristicData: logCharData)
                }
            }
            
            Text(drinkOnKit.error.description)
                .frame(alignment: .leading)
            Text(drinkOnKit.state.description)
                .frame(alignment: .leading)
        }
        .navigationBarTitle("DrinkOn Peripheral", displayMode: .inline)
        
        .onDisappear() {
            drinkOnPeripheral.disconnect()
        }
        .onAppear() {
            //print("**** On Appear")
            DrinkOnKit.sharedInstance.stopScanForPeripherals()
            drinkOnPeripheral.connect(options: .readAll)
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
