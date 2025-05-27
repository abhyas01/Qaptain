//
//  ProfileView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/26/25.
//

import SwiftUI

struct ProfileView: View {
    
    let userId: String
    
    @EnvironmentObject private var authController: AuthController
    
    @State private var userModel: User?
    
    var body: some View {
        
        NavigationStack {
            Group {
                if let userModel = userModel {
                   
                    List {
                        Section("Full Name") {
                            Text(userModel.name)
                        }
                        
                        Section("Email") {
                            Text(userModel.email)
                        }
                        
                        Button {
                            authController.signout()
                        } label: {
                            HStack {
                                Label("Logout", systemImage: "lock")
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    
                } else {
                    VStack {
                        ProgressView()
                        
                        Text("Loading...")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }
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
            getUserModel()
        }
    }
    
    private func getUserModel() {
        Task {
            let user = await DataManager.shared.getUser(userId: userId)
            withAnimation {
                userModel = user
            }
        }

    }
}

#Preview {
    ProfileView(userId: "3rNFDKJebENEfHqVFg475bJXb9j1")
        .environmentObject(AuthController.shared)
}
