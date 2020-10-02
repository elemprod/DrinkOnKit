//
//  ConnectRowView.swift
//  
//
//  Created by Ben Wirz on 10/2/20.
//

import SwiftUI


@available(iOS 13.0, *)
public class connectRowData: NSObject, Identifiable, ObservableObject {
    
    /// Uniquie ID number for the object
    public let id = UUID()
    
    @Published var title : String
    @Published var value : String
    
    init(title : String, value : String) {
        self.title = title
        self.value = value
    }
}


struct ConnectRowView: View {
    @EnvironmentObject var data : connectRowData
    
    var body: some View {
        HStack {
            Text(data.title)
            Text(data.value)
            Spacer()
        }

    }
}

struct ConnectRowView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let data = connectRowData(title: "Title", value: "Value")
            ConnectRowView()
                .environmentObject(data)
        }
        .previewLayout(.fixed(width: 300, height: 40))

    }
}
