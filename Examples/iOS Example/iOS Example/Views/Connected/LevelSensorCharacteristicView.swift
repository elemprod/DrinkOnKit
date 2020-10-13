//
//  LevelSensorCharacteristicView.swift
//  iOS Example
//
//  Created by Ben Wirz on 10/7/20.
//

import SwiftUI
import DrinkOnKit

extension Binding {
    
    /// When the `Binding`'s `wrappedValue` changes, the given closure is executed.
    /// - Parameter closure: Chunk of code to execute whenever the value changes.
    /// - Returns: New `Binding`.
    func onUpdate(_ closure: @escaping () -> Void) -> Binding<Value> {
        Binding(get: {
            wrappedValue
        }, set: { newValue in
            wrappedValue = newValue
            closure()
        })
    }
}

struct LevelSensorCharListHeader: View {
    
    var body: some View {
        Text("Level Sensor Characteristic")
    }
}
struct LevelSensorCharacteristicView: View {
    
    // Enable Level Sensor Notifications?
    @State private var levelSensorNotify : Bool = false
    
    
    private func levelSensorNotifyUpdated() {
        if(self.levelSensorNotify) {
            if drinkOnPeripheral.peripheral.state == .connected {
                // already connected so just enable  notifications manually
                drinkOnPeripheral.options.insert(.disableDisconnect)
                drinkOnPeripheral.options.insert(.notifyLevelSensorChar)
                drinkOnPeripheral.levelSensorNotificationsEnable(true)
            } else if drinkOnPeripheral.peripheral.state == .disconnected {
                // connect with notifications enabled
                drinkOnPeripheral.connect(options: .enableLevelSensorNotifications)
            } else {
                levelSensorNotify = false   // in the connecting / disconnecting state, notifications couldn't be enabled now
            }
            
        } else {
            if drinkOnPeripheral.peripheral.state == .connected {
                // already connected so just disable notifications manually
                drinkOnPeripheral.options.remove(.disableDisconnect)
                drinkOnPeripheral.options.remove(.notifyLevelSensorChar)
                drinkOnPeripheral.levelSensorNotificationsEnable(false)
            }
        }
    }

    
    @ObservedObject var drinkOnPeripheral : DrinkOnPeripheral
    
    var characteristicData : DrinkOnLevelSensorCharacteristic
    
    var body: some View {
        Section(header: LevelSensorCharListHeader()) {
            Toggle(isOn: $levelSensorNotify.onUpdate(levelSensorNotifyUpdated)) {
                Text("Notifications")
            }
            HStack {
                Text("Sensor Raw")
                Spacer()
                Text(String(format: "%d cnts", characteristicData.levelSensor))
            }
        }
    }
}

/*
struct LevelSensorCharacteristicView_Previews: PreviewProvider {
    
    static var previews: some View {
        let previewCharData = DrinkOnLevelSensorCharacteristic(levelSensor: 16321)
        LevelSensorCharacteristicView(levelSensorNotify: false, characteristicData: previewCharData)
    }
}
*/
