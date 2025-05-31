//
//  SplashScreen.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/21/25.
//

import SwiftUI

// MARK: - Splash Screen View

/// UIViewControllerRepresentable wrapper for displaying the app's launch screen
struct SplashScreen: UIViewControllerRepresentable {
    
    // MARK: - UIViewControllerRepresentable Implementation

    func makeUIViewController(context: Context) -> some UIViewController {
        
        // Load the LaunchScreen storyboard from the main bundle
        let storyboard = UIStoryboard(name: "LaunchScreen", bundle: nil)
        
        // Get the initial view controller configured in the storyboard
        let controller = storyboard.instantiateInitialViewController()!
        
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        // No updates needed for a static launch screen
    }
}
