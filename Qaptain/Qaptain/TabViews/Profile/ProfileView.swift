//
//  ProfileView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/26/25.
//

import SwiftUI

/// User profile management view that provides account information display and management
struct ProfileView: View {
    
    // MARK: - Properties

    /// Unique identifier of the currently authenticated user
    let userId: String
    
    // MARK: - Environment Dependencies

    /// Shared authentication controller managing Firebase Auth state and operations
    @EnvironmentObject private var authController: AuthController
    
    // MARK: - State Properties
    
    /// Complete user model containing all user information from Firebase Firestore
    @State private var userModel: User?
    
    /// Controls the presentation of the name editing modal sheet
    @State private var nameEditSheet: Bool = false
    
    // MARK: - Body

    var body: some View {
        
        NavigationStack {
            Group {
                
                // Data Display Section
                if let userModel = userModel {
                   
                    List {
                        
                        // Editable full name section with navigation to name editing interface
                        Section("Full Name") {
                            Button {
                                nameEditSheet = true
                            } label: {
                                
                                HStack{
                                    Text(userModel.name)
                                    
                                    Spacer()
                                    
                                    // Chevron right icon indicating this row is tappable and leads to another view
                                    Image(systemName: "chevron.right")
                                }
                            }
                        }
                        
                        // Read-only email display section
                        Section("Email") {
                            Text(userModel.email)
                        }
                        
                        // Logout Section
                        Button {
                            print("🚪 [ProfileView] User initiated logout process")
                            authController.signout()
                        } label: {
                            HStack {
                                Label("Logout", systemImage: "lock")
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                
                // Loading State Section
                } else {
                    VStack {
                        ProgressView()
                        
                        Text("Loading...")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            
            // Modal Sheet Configuration
            .sheet(isPresented: $nameEditSheet) {
                if let userModel = userModel {
                    NameEditSheet(
                        userId: userId,
                        name: userModel.name,
                        onSuccess: {
                            print("🎉 [ProfileView] Name edit success callback triggered - refreshing user data")

                            // Clear current user model to trigger loading state
                            self.userModel = nil
                            
                            // Fetch updated user data from Firebase
                            self.getUserModel()
                        }
                    )
                }
            }
            
            // Navigation Configuration
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "person.fill")
                        
                        Text(
                        "Profile"
                        )
                        .font(.title3)
                        .fontDesign(.rounded)
                        .fontWeight(.bold)
                    }
                    .foregroundStyle(.orange)
                }
            }
        }
        .tint(.orange)
        .accentColor(.orange)
        .onAppear {
            print("👁️ [ProfileView] View appeared - initiating user data fetch")
            getUserModel()
        }
    }
    
    // MARK: - Data Fetching Methods

    /// Fetches complete user model from Firebase Firestore using the user's unique ID
    private func getUserModel() {
        Task {
            let user = await DataManager.shared.getUser(userId: userId)
            withAnimation {
                userModel = user
            }
        }

    }
}

// MARK: - Preview

#Preview {
    ProfileView(userId: "3rNFDKJebENEfHqVFg475bJXb9j1")
        .environmentObject(AuthController.shared)
}
