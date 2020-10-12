//
//  LevelSensorCharacteristicView.swift
//  iOS Example
//
//  Created by Ben Wirz on 10/7/20.
//

import SwiftUI
import DrinkOnKit

struct LevelSensorCharListHeader: View {
    var body: some View {
        Text("Level Sensor Characteristic")
    }
}
struct LevelSensorCharacteristicView: View {
    var characteristicData : DrinkOnLevelSensorCharacteristic
    
    var body: some View {
        Section(header: LevelSensorCharListHeader()) {
            HStack {
                Text("Sensor Raw")
                Spacer()
                Text(String(format: "%d cnts", characteristicData.levelSensor))
            }
        }
    }
}

struct LevelSensorCharacteristicView_Previews: PreviewProvider {
    
    static var previews: some View {
        let previewCharData = DrinkOnLevelSensorCharacteristic(levelSensor: 16321)
        LevelSensorCharacteristicView(characteristicData: previewCharData)
    }
}
