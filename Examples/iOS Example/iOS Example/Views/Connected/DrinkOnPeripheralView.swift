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
                
                if drinkOnPeripheral.state == .connected  {
                    Text("Connected")
                        .frame(height: 10)
                } else {
                    Text("Disconnected")
                        .frame(height: 10)
                }
                
                
                Unwrap(drinkOnPeripheral.levelSensor) { levelSensor in
                    HStack {
                        Text("Level Sensor")
                        Spacer()
                        Text(String(format: "%d cnts", levelSensor))
                    }
                }
                
                Unwrap(drinkOnPeripheral.statusCharacteristic) { charData in
                    StatusCharacteristicView(characteristicData: charData)
                }
                
                Unwrap(drinkOnPeripheral.infoCharacteristic) { charData in
                    InfoCharacteristicView(characteristicData: charData)
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
