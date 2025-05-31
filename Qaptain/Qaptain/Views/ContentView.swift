//
//  ContentView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/23/25.
//

import SwiftUI

/// Main App Content View
struct ContentView: View {
    
    // MARK: - Dependencies

    /// Singleton authentication controller that manages Firebase Auth state
    /// Observes authentication changes and provides current user information
    /// Automatically updates UI when auth state changes (login/logout/session expiry)
    @EnvironmentObject private var authController: AuthController
    
    // MARK: - State Properties

    /// Controls the display of the splash screen overlay
    /// Initially true to show splash screen, set to false after initialization delay
    /// Manages smooth transition animations between splash and main content
    @State private var showSplashScreen: Bool = true
    
    // MARK: - View Body

    var body: some View {
        ZStack {
            
            // MARK: - Main Content Layer

            Group {
                switch authController.authStatus {
                    
                case .authenticated:
                    
                    // User is successfully logged in - show main app interface
                    AuthenticatedView(userId: authController.userId)
                    
                case .unauthenticated:
                    
                    // User needs to log in - show authentication interface
                    AuthView()
                    
                case .undefined:
                    
                    // Authentication state is still being determined - show loading indicator
                    ProgressView()
                }
            }
            
            // Splash Screen Overlay
            if showSplashScreen {
                
                /// Splash screen overlay with smooth transition animations
                SplashScreen()
                    .ignoresSafeArea()
                    .zIndex(1)
                    .transition(.asymmetric(
                        insertion: .opacity.animation(.linear(duration: 0)),
                        removal: .opacity.animation(.easeOut(duration: 0.3))
                    ))
                    .onAppear {
                        
                        // Schedule splash screen dismissal after app initialization
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                showSplashScreen = false
                        }
                    }
            }
        }
        
        // Apply network connectivity monitoring across the entire app
        .networkAlert()
    }
}

// MARK: - Preview

#Preview {
    ContentView()
}
