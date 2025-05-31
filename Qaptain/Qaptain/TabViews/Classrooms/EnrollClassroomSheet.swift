//
//  EnrollClassroomSheet.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/27/25.
//

import SwiftUI

/// Modal sheet view for students to join existing classrooms using teacher-provided passwords
struct EnrollClassroomSheet: View {
    
    // MARK: - Environment Dependencies

    /// Environment value to programmatically dismiss this modal sheet
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties

    /// The ID of the student attempting to join a classroom
    let userId: String
    
    /// Optional callback executed after successful classroom enrollment
    var onSuccessfulEnrollment: (() -> Void)? = nil
    
    // MARK: - State Properties

    /// Should match the UUID password generated when teacher created the classroom
    @State private var password: String = ""
    
    /// Flag indicating whether the enrollment request is in progress
    @State private var isJoining: Bool = false
    
    /// Error message to display when enrollment fails
    @State private var errorMessage: String? = nil
    
    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                
                // Password Input Section
                Section("Classroom Password") {
                    TextField("Type Classroom Password", text: $password)
                }
                
                // Join Button Section
                Button {
                    joinClassroom()
                } label: {
                    HStack {
                        Text("Join Classroom")
                        
                        if isJoining {
                            ProgressView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(isJoining)
                .buttonStyle(.borderedProminent)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                
                // Error Message Display
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            
            // Navigation Bar Configuration
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Join Classroom")
                        .fontDesign(.rounded)
                        .foregroundStyle(.orange)
                        .fontWeight(.bold)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        
                        Button {
                            dismissKeyboard()
                        } label: {
                            Image(
                                systemName: "keyboard.chevron.compact.down"
                            )
                            .tint(.orange)
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    // MARK: - Classroom Enrollment Logic

    /// Initiates the classroom enrollment process through DataManager
    private func joinClassroom() {
        print("🏫 [EnrollClassroomSheet] Starting classroom enrollment process")

        withAnimation {
            isJoining = true
            errorMessage = nil
        }
        
        DataManager.shared.joinClassroom(
            userId: userId,
            password: password,
            completionHandler: { success in
                print("📡 [EnrollClassroomSheet] Received response from DataManager: \(String(describing: success))")

                DispatchQueue.main.async {
                    
                    // Clear loading state
                    withAnimation {
                        isJoining = false
                    }
                    
                    // Handle different response scenarios
                    switch success {
                        
                    case true:
                        
                        // Enrollment successful
                        print("🎉 [EnrollClassroomSheet] Classroom enrollment successful!")

                        dismiss()
                        onSuccessfulEnrollment?()
                        
                    case false:
                        
                        // Validation failed (invalid password or already enrolled)
                        withAnimation {
                            errorMessage = "Invalid password or you're already enrolled in this class."
                        }
                        
                    case nil:
                        
                        // System error (network, database, server issues)
                        withAnimation {
                            errorMessage = "An unexpected error occurred. Try later?"
                        }
                        
                    case .some(_):
                        break
                    }
                }
            }
        )

        print("📡 [EnrollClassroomSheet] Enrollment request sent to DataManager")
    }
    
    // MARK: - Helper Methods

    /// Programmatically dismisses the on-screen keyboard
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(
                UIResponder.resignFirstResponder
            ),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Preview

#Preview {
    EnrollClassroomSheet(userId: "3rNFDKJebENEfHqVFg475bJXb9j1")
}
