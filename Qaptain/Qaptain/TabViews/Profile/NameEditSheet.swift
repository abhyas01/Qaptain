//
//  NameEditSheet.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/31/25.
//

import SwiftUI

/// Modal sheet view for editing and updating user names throughout the entire Qaptain application
struct NameEditSheet: View {
    
    // MARK: - Environment Dependencies

    /// SwiftUI environment value for programmatically dismissing this modal sheet
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Properties

    /// Unique identifier of the user whose name is being edited
    let userId: String
    
    /// Current user's name that will be edited and potentially updated
    @State var name: String
    
    /// Callback function executed when name update is successful
    let onSuccess: () -> Void
    
    // MARK: - State Properties

    /// Loading state indicator for name update operations
    @State private var isLoading: Bool = false
    
    /// Error state indicator for failed name update operations
    @State private var hasError: Bool = false
    
    // MARK: - Computed Properties

    /// Processed and cleaned version of the user's name input
    private var cleanedName: String {
        return cleanAndCapitalizeFullName(name)
    }
    
    /// Validation status indicating whether the cleaned name meets all requirements
    private var isValidName: Bool {
        cleanedName.count >= 7
        &&
        cleanedName.count <= 20
    }
    
    // MARK: - Body

    var body: some View {
        NavigationStack {
            Form {
                
                // Name Input Section
                // Text field for entering the new user name
                // Uses a binding that automatically applies cleaning/formatting
                // Real-time updates show the cleaned version as user types
                TextField("Name Update",
                          text: Binding(
                            get: { cleanedName },
                            set: { name = $0 }
                          )
                )
                
                // Update Button Section
                // Primary action button for submitting name changes
                // Dynamically displays loading, error, or normal states
                // Disabled when name is invalid or operation is in progress
                Button {
                    updateName()
                } label: {
                    Group {
                        
                        // Loading State Display
                        if isLoading {
                            HStack {
                                ProgressView()
                                Text("Loading...")
                            }
                            
                        // Error State Display with Retry Functionality
                        } else if hasError {
                            Label(
                                "Error occurred while renaming. Try again?",
                                systemImage: "exclamationmark.triangle.fill"
                            )
                            .foregroundStyle(.white)
                            
                        // Normal State Display
                        } else {
                            Text("Update")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .font(.title3)
                }
                .disabled(!isValidName)
                .padding()
                .buttonStyle(.borderedProminent)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets())
                
                // Helper text providing validation requirements to the user
                // Explains the character count requirements for valid names
                Text("Enter a name between 7 and 20 characters.")
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .listRowInsets(EdgeInsets())
            }
            .presentationDetents([.medium])
            
            // Navigation Configuration
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Update Name")
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
    }
    
    // MARK: - Name Update Logic

    /// Updates the user's name everywhere it appears in the Firebase database
    private func updateName() {
        
        // Set loading state and clear any previous errors
        withAnimation {
            isLoading = true
            hasError = false
        }
        
        // Call DataManager to perform global name update across all collections
        DataManager.shared.updateUserNameEverywhere(
            userId: userId,
            newName: cleanedName,
            completionHandler: { success in
                print("📡 [NameEditSheet] Received response from DataManager.updateUserNameEverywhere: \(success)")

                DispatchQueue.main.async {
                    
                    withAnimation {
                        isLoading = false
                    }
                    
                    if success {
                        print("🎉 [NameEditSheet] Name update successful - executing success callback and dismissing")
                        
                        withAnimation {
                            onSuccess()
                            dismiss()
                        }
                        
                    } else {
                        print("❌ [NameEditSheet] Name update failed - showing error state")

                        withAnimation {
                            hasError = true
                        }
                        
                    }
                    
                }
            }
        )
    }

    // MARK: - Helper Methods

    /// Cleans and properly capitalizes user's full name for consistent formatting
    /// Removes extra whitespace and capitalizes each word for professional appearance
    /// - Parameter fullName: Raw full name input from user
    /// - Returns: Cleaned and properly formatted full name
    private func cleanAndCapitalizeFullName(_ fullName: String) -> String {
        
        // Remove leading and trailing whitespace
        let trimmedFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Split by whitespace and remove empty components
        let components = trimmedFullName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        // Capitalize each word properly (first letter uppercase, rest lowercase)
        let capitalizedComponents = components.map { word in
            word.prefix(1).uppercased() + word.dropFirst().lowercased()
        }
        
        return capitalizedComponents.joined(separator: " ")
    }
    
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
    NameEditSheet(
        userId: "3rNFDKJebENEfHqVFg475bJXb9j1",
        name: "Abhyas"
    ) {}
}
