//
//  StatusCharacteristicView.swift
//  iOS Example
//
//  Created by Ben Wirz on 10/6/20.
//

import SwiftUI
import DrinkOnKit

struct StatusCharListHeader: View {
    var body: some View {
        Text("Status Characteristic")
    }
}

struct StatusCharacteristicView: View {
    var characteristicData : DrinkOnStatusCharacteristic
    
    var body: some View {
        
        Section(header: StatusCharListHeader()) {
            HStack {
                Text("Goal (24hr)")
                Spacer()
                Text(String(format: "%.1f Bottles", characteristicData.goal24hr))
            }
            HStack {
                Text("Bottle Level")
                Spacer()
                Text(String(format: "%d%%", characteristicData.bottleLevel))
            }
            HStack {
                Text("Consumed (24hr)")
                Spacer()
                Text(String(format: "%.1f Bottles", characteristicData.consumed24hr))
            }
            HStack {
                Text("UI State Code")
                Spacer()
                Text(String(format: "%d", characteristicData.UIStateCode))
            }
            HStack {
                Text("Battery")
                Spacer()
                Text(String(format: "%d %%", characteristicData.batteryLevel))
            }
            HStack {
                Text("Run Time")
                Spacer()
                Text(String(format: "%d hrs", characteristicData.runTime))
            }
        }
    }
}

struct StatusCharacteristicView_Previews: PreviewProvider {
    static var previews: some View {
        let previewCharData : DrinkOnStatusCharacteristic = DrinkOnStatusCharacteristic(
            goal24hr: 5.0,
            bottleLevel: 84,
            consumed24hr: 4.3,
            UIStateCode: 4,
            batteryLevel: 54,
            runTime: 1202)
        StatusCharacteristicView(characteristicData: previewCharData)
    }
}
