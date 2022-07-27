//
//  ContentView.swift
//  Shared
//
//  Created by Alexandru Dranca on 27.07.2022.
//

import SwiftUI

struct ContentView: View {
    @State var showPopver = false
    var body: some View {
        Button("Tap me") {
            showPopver = true
        }
        .sheet(isPresented: $showPopver) {
            Popover()
        }
            
            
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
