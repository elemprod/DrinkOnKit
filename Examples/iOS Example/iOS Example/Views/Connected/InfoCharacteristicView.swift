//
//  InfoCharacteristicView.swift
//  iOS Example
//
//  Created by Ben Wirz on 10/6/20.
//

import SwiftUI
import DrinkOnKit

struct InfoCharListHeader: View {
    var body: some View {
        Text("Info Characteristic")
    }
}

struct InfoCharacteristicView: View {
    
    var characteristicData : DrinkOnInfoCharacteristic
    
    var body: some View {
        List(){
            Section(header: InfoCharListHeader()) {
                HStack {
                    Text("Firmware Version")
                    Spacer()
                    Text(characteristicData.firmwareVersion)
                }
                HStack {
                    Text("DFU Code")
                    Spacer()
                    Text(String(characteristicData.dfuCode))
                }
                HStack {
                    Text("Model")
                    Spacer()
                    Text(String(characteristicData.modelCode))
                }
                HStack {
                    Text("Hardware Version")
                    Spacer()
                    Text(characteristicData.hardwareCode)
                }
            }

        }
        
    }
}

struct InfoCharacteristicView_Previews: PreviewProvider {
    
    static var previews: some View {
        let previewInfoCharData : DrinkOnInfoCharacteristic = DrinkOnInfoCharacteristic(
            firmwareVersion: "0.153",
            dfuCode: 11,
            modelCode: 100,
            hardwareCode: String("F")
        )
        
        InfoCharacteristicView(characteristicData: previewInfoCharData)
    }
}
