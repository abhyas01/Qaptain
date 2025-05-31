//
//  AuthenticatedView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/24/25.
//

import SwiftUI

/// Main container view that displays the authenticated user interface with tab navigation
/// This view is shown only when a user is successfully logged in and provides access to
/// the core app functionality through a tab-based navigation system.
///
/// Features:
/// - Tab-based navigation between Classrooms and Profile sections
/// - Passes authenticated user ID to child views for data operations
/// - Smooth animations between tab selections
/// - Maintains user session state throughout navigation
struct AuthenticatedView: View {
    
    // MARK: - Properties

    /// The unique identifier of the authenticated user
    /// Used throughout the app for data fetching, permissions, and user-specific operations
    let userId: String
    
    // MARK: - Tab Types

    /// Enumeration defining available tab options in the authenticated interface
    /// Each case represents a major section of the application
    enum TabType {
        case classrooms
        case profile
    }
    
    // MARK: - State Properties

    /// Currently selected tab in the tab view
    /// Defaults to classrooms as the primary user destination
    @State private var selectedTab: TabType = .classrooms
    
    // MARK: - Body

    var body: some View {
        
        // Log user authentication success and view initialization
         let _ = print("🔐 AuthenticatedView: Displaying authenticated interface for user ID: \(userId)")
        
        TabView(selection: $selectedTab) {
            
            // MARK: - Classrooms Tab

            Tab("Classrooms",
                systemImage: "book",
                value: TabType.classrooms
            ) {
                ClassroomsView(
                    userId: userId
                )
            }
            
            // MARK: - Profile Tab

            Tab("Profile",
                systemImage: "person",
                value: TabType.profile
            ) {
                ProfileView(
                    userId: userId
                )
            }
        }
        
        // Add smooth animation when switching between tabs
        .animation(.easeInOut, value: selectedTab)
        
        // Log tab changes for user behavior tracking
        .onChange(of: selectedTab) { oldValue, newValue in
            print("🔄 AuthenticatedView: Tab changed from \(oldValue) to \(newValue)")
        }
    }
}

// MARK: - Preview

#Preview {
    AuthenticatedView(userId: "3rNFDKJebENEfHqVFg475bJXb9j1")
}
