//
//  CreateClassroomSheet.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/26/25.
//

import SwiftUI

/// Modal sheet view for creating new classrooms in the Qaptain app
/// This view is presented when teachers want to create a new classroom for their students
struct CreateClassroomSheet: View {
    
    // MARK: - Environment Dependencies

    /// Environment value to programmatically dismiss this modal sheet
    /// Called on successful creation or user cancellation
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties

    /// The ID of the user creating the classroom
    let userId: String
    
    /// Optional callback executed after successful classroom creation
    var onClassroomCreated: (() -> Void)? = nil
    
    // MARK: - State Properties

    /// Raw classroom name input by the user
    @State private var classroomName: String = ""
    
    /// Flag indicating whether the creation request is in progress
    @State private var isCreating: Bool = false
    
    /// Error message to display to the user when creation fails
    @State private var errorMessage: String? = nil
    
    // MARK: - Computed Properties

    /// Cleaned and normalized version of the classroom name
    private var trimmedClassroomName: String {
        let trimmedName = classroomName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let components = trimmedName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return components.joined(separator: " ")
    }
    
    /// Validates whether the current classroom name meets all requirements
    private var isClassroomNameValid: Bool {
        let count = trimmedClassroomName.count
        return count >= 8 && count <= 150
    }
    
    // MARK: - View Body

    var body: some View {
        NavigationStack {
            Form {
                
                // Classroom Name Input Section
                Section("Classroom Name") {
                    TextField("Type Classroom Name", text: $classroomName)
                }
                
                // Submit Button Section
                Button {
                    
                    print("🚀 [CreateClassroomSheet] User tapped create classroom button")
                    createClassroom()
                } label: {
                    HStack {
                        Text("Create Classroom")
                        
                        if isCreating {
                            ProgressView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!isClassroomNameValid || isCreating)
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
                    Text("Create Classroom")
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
    
    // MARK: - Classroom Creation Logic

    /// Initiates the classroom creation process through DataManager
    private func createClassroom() {
        
        // Set loading state and clear any previous errors
        withAnimation {
            isCreating = true
            errorMessage = nil
        }
        
        print("⏳ [CreateClassroomSheet] UI state updated - loading: true, error cleared")
        
        // Initiate creation through DataManager
        DataManager.shared.createClassroom(
            userId: userId,
            withClassroomName: trimmedClassroomName
        ) { result in
            
            print("📡 [CreateClassroomSheet] Received response from DataManager: \(String(describing: result))")

            DispatchQueue.main.async {

                // Clear loading state
                withAnimation {
                    isCreating = false
                }
                
                // Handle different response scenarios
                switch result {
                
                case true:
                    
                    // Dismiss the modal sheet
                    dismiss()
                    
                    // Execute callback to refresh parent view
                    onClassroomCreated?()
                    
                case false :
                    
                    // Validation failed (duplicate name or invalid length)
                    withAnimation {
                        errorMessage = "Name must be unique and 8–150 characters."
                    }
                    
                case nil:
                    
                    // System error (network, database, etc.)
                    withAnimation {
                        errorMessage = "An unexpected error occurred. Try later?"
                    }
                
                case .some(_):
                    break
                }
            }
        }
        
        print("📡 [CreateClassroomSheet] Creation request sent to DataManager")
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
    CreateClassroomSheet(userId: "3rNFDKJebENEfHqVFg475bJXb9j1")
}
