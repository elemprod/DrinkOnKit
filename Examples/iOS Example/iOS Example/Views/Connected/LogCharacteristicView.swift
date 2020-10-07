//
//  LogCharacteristicView.swift
//  iOS Example
//
//  Created by Ben Wirz on 10/7/20.
//

import SwiftUI
import DrinkOnKit

struct LogCharListHeader: View {
    var body: some View {
        Text("Status Characteristic")
    }
}

struct LogCharacteristicView: View {
    var characteristicData : DrinkOnLogCharacteristic
    
    var body: some View {
        List{
            Section(header: LevelSensorCharListHeader()) {
                ForEach(characteristicData.log) { logPoint in
                    HStack {
                        if(logPoint.hour == 0) {
                            Text("Now")
                        } else {
                            Text(String(format: "minus %d hours", logPoint.hour))
                        }
                        
                        Spacer()
                        Text(String(format: "%1.1f", logPoint.consumed))
                    }
                }
            }
        }
        
    }
}

struct LogCharacteristicView_Previews: PreviewProvider {
       static var previews: some View {
        let log : [Float] = [1.0, 2.5, 0.0, 3.4, 0, 0, 0, 1, 2, 3, 2.2, 0, 3.1]
        let previewCharData : DrinkOnLogCharacteristic = DrinkOnLogCharacteristic(logValues: log, firstOffsettHour: 0)

        LogCharacteristicView(characteristicData: previewCharData)
    }
}
