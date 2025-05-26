//
//  AuthenticatedView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/24/25.
//

import SwiftUI

struct AuthenticatedView: View {
    
    let userId: String
    
    enum TabType {
        case classrooms
        case profile
    }
    
    @State private var selectedTab: TabType = .classrooms
    
    var body: some View {
        TabView(selection: $selectedTab) {
            
            Tab("Classrooms",
                systemImage: "book",
                value: TabType.classrooms
            ) {
                ClassroomsView(
                    userId: userId
                )
            }
            
            Tab("Profile",
                systemImage: "person",
                value: TabType.profile
            ) {
                Text("Profile")
            }
        }
        .animation(.easeInOut, value: selectedTab)
    }
}

#Preview {
    AuthenticatedView(userId: "3rNFDKJebENEfHqVFg475bJXb9j1")
}
