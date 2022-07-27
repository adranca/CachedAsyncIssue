//
//  ContentView.swift
//  Shared
//
//  Created by Alexandru Dranca on 27.07.2022.
//

import SwiftUI

enum Action: String, Identifiable {
    var id: String {
        return self.rawValue
    }
    case kingfisher
    case asyncImage
}

struct ContentView: View {
    @State var action: Action? = nil
    @State var showPopver = false
    var body: some View {
        VStack {
            Button("Kingfisher") {
                action = .kingfisher
            }
            
            Button("AsyncImage") {
                action = .asyncImage
            }
        }
        .sheet(item: $action) { action in
            switch action {
            case .kingfisher:
                KingfisherPopover()
            case .asyncImage:
                Popover()
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
