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
    
    // MARK: - Authentication State Management

    /// Centralized authentication controller managing Firebase Auth integration
    @StateObject private var authController = AuthController.shared
    
    // MARK: - Application Initialization

    init() {
        
        // Initialize Firebase SDK with configuration from GoogleService-Info.plist
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                
                // To serve as authentication-aware interface
                .environmentObject(authController)
            
                .onAppear {
                    
                    // Start listening for Firebase authentication state changes
                    authController.listenToAuthChanges()
                }
        }
    }
}
