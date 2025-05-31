//
//  NetworkAlertModifier.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/30/25.
//

import SwiftUI

/// A custom ViewModifier that provides network connectivity alerts across the entire application
/// This modifier monitors network status and automatically displays an alert when internet connection is lost
/// Used to inform users about connectivity issues that may affect Firebase operations and data synchronization
///
/// Usage: Apply to any view using .networkAlert() extension method
/// The modifier will automatically show/hide alerts based on NetworkMonitor's connectivity state
struct NetworkAlertModifier: ViewModifier {
    
    // MARK: - Properties

    /// Observes the shared NetworkMonitor instance for real-time connectivity changes
    /// Uses @StateObject to ensure the NetworkMonitor lifecycle is managed properly
    @StateObject private var networkMonitor = NetworkMonitor.shared
    
    // MARK: - View Modifier Implementation

    func body(content: Content) -> some View {
        content
            .alert("No Internet Connection", isPresented: $networkMonitor.showNetworkAlert) {
                Button("OK") {
                    print("📡 NetworkAlertModifier: User dismissed network connection alert")
                }
            } message: {
                Text("Please check your internet connection and try again.")
            }
    }
}
