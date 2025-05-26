//
//  ContentView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/23/25.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject private var authController: AuthController
    
    var body: some View {
        switch authController.authStatus {
        case .authenticated:
            AuthenticatedView(userId: authController.userId)
        case .unauthenticated:
            AuthView()
        case .undefined:
            ProgressView()
        }
    }
}

#Preview {
    ContentView()
}
