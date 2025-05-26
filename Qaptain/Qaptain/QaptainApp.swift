//
//  QaptainApp.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/23/25.
//

import SwiftUI
import FirebaseCore

@main
struct QaptainApp: App {
    
    @StateObject private var authController = AuthController.shared
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authController)
                .onAppear {
                    authController.listenToAuthChanges()
                }
        }
    }
}
