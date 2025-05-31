//
//  ClassroomDetailView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/24/25.
//

import SwiftUI

/// Comprehensive detail view for individual classrooms that provides different functionality
/// based on user role (creator/teacher vs student). This view serves as the main hub for
/// classroom management and navigation to classroom-specific features.
///
/// Key Features for Creators:
/// - Classroom name editing with validation and uniqueness checking
/// - Password regeneration and sharing capabilities
/// - Classroom deletion with confirmation
/// - Full access to quizzes and member management
///
/// Key Features for Students:
/// - View classroom information and details
/// - Access to quizzes and member lists
/// - Ability to unenroll from classroom
/// - Copy classroom password for sharing
struct ClassroomDetailView: View {
    
    // MARK: - Immutable Properties

    /// Unique identifier of the current user accessing this classroom
    /// Used for permission checks and database operations
    let userId: String
    
    /// Firestore document ID of the classroom being displayed
    /// Primary key for all classroom-related database operations
    let documentId: String
    
    /// Date when the classroom was originally created
    /// Used for validation and display purposes
    let createdAt: Date
    
    /// Full name of the user who created this classroom
    /// Displayed in the header for identification
    let createdByName: String
    
    /// Boolean indicating if current user is the classroom creator
    /// Determines access level and available functionality throughout the view
    let isCreator: Bool
    
    // MARK: - Environment Properties

    /// SwiftUI environment value for dismissing the current view
    /// Used when classroom is deleted or user unenrolls
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Password Management State

    /// Tracks whether password copy action feedback should be shown
    /// Provides visual confirmation when password is copied to clipboard
    @State private var didCopy = false
    
    /// Tracks whether password regeneration success feedback should be shown
    /// Provides visual confirmation when new password is generated
    @State private var didRegenerate = false
    
    /// Loading state for password regeneration operation
    /// Shows progress indicator during network operation
    @State private var isRegenerating = false
    
    // MARK: - Name Editing State

    /// Controls whether classroom name is in editing mode
    /// Switches between display and editing interfaces
    @State private var isEditingName = false
    
    /// Temporary storage for edited classroom name during editing session
    /// Reverts to original name if editing is cancelled
    @State private var editedName: String
    
    /// Loading state for name save operation
    /// Shows progress indicator during database update
    @State private var isSavingEdit = false
    
    // MARK: - Dynamic Classroom Data
    
    /// Current classroom name (can be updated through editing)
    /// Synchronized with Firestore and updated in real-time
    @State private var classroomName: String
    
    /// Current classroom password (can be regenerated)
    /// Updated when password regeneration is successful
    @State private var classroomPassword: String
    
    // MARK: - Alert and Error State

    /// Controls display of duplicate name error alert
    /// Shown when user tries to use a classroom name that already exists
    @State private var duplicateAlert: Bool = false
    
    // MARK: - Classroom Delete and Student Unenrollment States
    
    /// Loading state for classroom deletion and student unenrollment operation
    /// Shows progress indicator during destructive operation
    @State private var isDeleting: Bool = false
    
    /// Error state for deletion or unenrollment operation
    @State private var errorInDeleting: Bool = false
    
    /// Controls display of deletion/unenrollment confirmation dialog
    /// Ensures user confirms destructive action before proceeding
    @State private var deleteAlert: Bool = false
    
    // MARK: - Initialization

    init(userId: String,
         documentId: String,
         classroomName: String,
         createdAt: Date,
         createdByName: String,
         isCreator: Bool,
         password: String
    ) {
        self.userId = userId
        self.documentId = documentId
        self.classroomName = classroomName
        self.createdAt = createdAt
        self.createdByName = createdByName
        self.isCreator = isCreator
        
        self.editedName = classroomName
        self.classroomPassword = password
    }
    
    // MARK: - Button Types Enum

    /// Defines available action buttons in the classroom detail interface
    enum ButtonType: CaseIterable {
        case quizzes
        case people
        
        /// Human-readable string representation for UI display
        var getString: String {
            switch self {
            case .quizzes:
                return "Quizzes"
            case .people:
                return "People"
            }
        }
        
        /// System icon image for visual identification
        var getIcon: Image {
            switch self {
            case .quizzes:
                return Image(systemName: "doc.text")
            case .people:
                return Image(systemName: "person.2.fill")
            }
        }
    }

    // MARK: - Computed Properties

    /// Processes and validates the edited classroom name
    /// Removes extra whitespace and normalizes spacing between words
    /// Used for validation and database operations
    private var trimmedEditedName: String {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let components = trimmedName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return components.joined(separator: " ")
    }

    /// Validates whether the edited name meets length requirements
    /// Classroom names must be between 8-150 characters
    private var isEditedNameValid: Bool {
        let count = trimmedEditedName.count
        return count >= 8 && count <= 150
    }

    // MARK: - Body

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 60) {
                        headerSection
                    
                        // Password Section (Creator Only)
                        if isCreator {
                            passwordSection
                        }
                    
                        // Navigation Buttons Section
                        VStack(spacing: 20) {
                            ForEach(ButtonType.allCases, id: \.self) {
                                sectionRow(type: $0)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Delete/Unenroll Button
                        deleteButton
                    }
                    .padding()
                    
                    Spacer()
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        
        // MARK: - Alert Configurations
        
        .alert("Renaming Failed", isPresented: $duplicateAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The classroom name must be unique among all classrooms you have created.")
        }
        
        .alert(isCreator ? "Are you sure?" : "Are you sure?", isPresented: $deleteAlert) {
            Button("Yes", role: .destructive) {
                if isCreator {
                    deleteThisClassroom()
                } else {
                    unenrollFromClass()
                }
            }
            Button("No", role: .cancel) {}
        } message: {
            Text(isCreator ?
                 "This Classroom will be permanently deleted." :
                 "You will be removed from this classroom. You can rejoin with the password anytime.")
        }
        
        // MARK: - Toolbar Configuration

        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(classroomName)                
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.orange)
                    .fontWeight(.bold)
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

    // MARK: - Header Section

    /// Displays classroom information header with editing capabilities for creators
    /// Shows classroom name, creator info, creation date, and edit controls
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                
                // Name Display/Editing Interface
                if isEditingName {
                    
                    TextEditor(
                        text: $editedName
                    )
                    .font(.title2)
                    .border(.gray, width: 2)
                    .frame(maxHeight: 200)
                    .disabled(isSavingEdit)

                } else {
                    Text(classroomName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }

                //  Edit Controls (Creator Only)
                if isCreator {
                    VStack(spacing: 8) {
                        
                        Button {
                            if !isEditingName {
                                
                                print("✏️ ClassroomDetailView: Entering edit mode")

                                withAnimation {
                                    isEditingName = true
                                }
                                
                            } else if isEditedNameValid {
                                
                                print("💾 ClassroomDetailView: Attempting to save edited name: '\(trimmedEditedName)'")

                                withAnimation {
                                    isSavingEdit = true
                                }
                                
                                // Call DataManager to update classroom name
                                DataManager.shared.updateClassroomName(
                                    documentId: documentId,
                                    userId: userId,
                                    withName: trimmedEditedName,
                                    completionHandler: { newName in
                                        print("📡 ClassroomDetailView: Received response from name update operation")

                                        DispatchQueue.main.async {
                                            
                                            withAnimation {
                                                isSavingEdit = false
                                                isEditingName = false
                                            }
                                            
                                            if let newName = newName {
                                                print("✅ ClassroomDetailView: Name update successful - New name: '\(newName)'")

                                                withAnimation {
                                                    classroomName = newName
                                                    editedName = newName
                                                }
                                                
                                            } else {
                                                print("❌ ClassroomDetailView: Name update failed - duplicate name or error")

                                                withAnimation {
                                                    editedName = classroomName
                                                    duplicateAlert = true
                                                }
                                            }
                                        }
                                    }
                                )
                            }
                        } label: {
                            if !isSavingEdit {
                                Image(
                                    systemName:
                                        isEditingName ?
                                    "checkmark.circle.fill"
                                    : "pencil.circle.fill"
                                )
                                .font(.title2)
                                .tint(isEditingName ? .green : .accentColor)
                                
                            } else {
                                ProgressView()
                            }
                        }
                        .disabled(isSavingEdit || (isEditingName && !isEditedNameValid))
                        
                        // Cancel Edit Button
                        if isEditingName {
                            Button {
                                print("🚫 ClassroomDetailView: Cancelling name edit")

                                withAnimation {
                                    isEditingName = false
                                    editedName = classroomName
                                }
                            } label: {
                                Image(systemName: "x.circle")
                                    .font(.title2)
                                    .tint(.gray)
                            }
                        }
                    }
                }
            }

            // Creator Information
            Text(createdByName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            // Creation Date
            Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.gray, radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Navigation Section Row

    /// Creates a navigation button for major app sections (Quizzes, People)
    /// Each button navigates to a different functional area of the classroom
    ///
    /// - Parameter type: The type of section this button represents
    /// - Returns: A styled NavigationLink with appropriate destination
    private func sectionRow(type: ButtonType) -> some View {
        NavigationLink {
            
            switch type {
            case .quizzes:
                
                QuizView(
                    userId: userId,
                    classroomId: documentId,
                    classroomName: classroomName,
                    createdByName: createdByName,
                    isCreator: isCreator
                )

            case .people:
                
                ClassMembersView(
                    classroomId: documentId,
                    isCreator: isCreator
                )
            }
            
        } label: {
            HStack {
                type.getIcon
                    .font(.title3)
                
                Text(type.getString)
                    .font(.body)
                
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(.orange)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.gray, radius: 2, x: 0, y: 1)
    }

    // MARK: - Delete/Unenroll Button

    /// Displays context-appropriate destructive action button
    /// Shows "Delete Classroom" for creators, "Unenroll" for students
    /// Includes loading states and error handling
    private var deleteButton: some View {
        Button {
            
            print("🚨 ClassroomDetailView: User initiated destructive action - IsCreator: \(isCreator)")
            deleteAlert = true
            
        } label: {
            
            if isDeleting {
                
                HStack {
                    ProgressView()
                    Text(isCreator ? "Deleting..." : "Unenrolling...")
                }
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(8)
                
            } else if errorInDeleting {
                
                Label(
                    isCreator ?
                        "Error occurred while deleting. Try again?" :
                        "Error occurred while unenrolling. Try again?",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(8)
                
            } else {
                
                Text(isCreator ? "Delete Classroom" : "Unenroll from Classroom")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                
            }
        }
        .disabled(isDeleting)
        .buttonStyle(.borderedProminent)
        .tint((isDeleting || errorInDeleting) ? .secondary : .red)
    }
    
    // MARK: - Password Section

    /// Displays classroom password management interface for creators
    /// Includes password display, copy functionality, and regeneration capability
    private var passwordSection: some View {
        VStack(alignment: .leading){
            
            HStack {
                Text("Password to join this class")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                
                Spacer()
                
                // Password regeneration button with state management
                if isRegenerating {
                    regenerateButton
                } else {
                    regenerateButton
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 8)
            
            // Password display and copy interface
            HStack {
                Text(classroomPassword)
                    .multilineTextAlignment(.leading)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .animation(.smooth, value: classroomPassword)
                
                Spacer()
                
                // Copy to clipboard button
                Button {
                    print("📋 ClassroomDetailView: Copying password to clipboard")

                    UIPasteboard.general.string = classroomPassword
                    
                    withAnimation {
                        didCopy = true
                    }
                    
                    // Reset copy feedback after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            didCopy = false
                        }
                    }
                } label: {
                    Image(systemName: didCopy ? "checkmark.circle.fill" : "list.clipboard.fill")
                        .foregroundStyle(didCopy ? .green : .orange)
                        .transition(.scale)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
    
    // MARK: - Password Regeneration Button

    /// Button for generating a new classroom password
    /// Includes loading state and success feedback
    private var regenerateButton: some View {
        Button {
            print("🔄 ClassroomDetailView: Initiating password regeneration")
            
            withAnimation {
                isRegenerating = true
            }
    
            // Call DataManager to generate new password
            DataManager.shared.regenerateClassroomPassword(
                documentId: documentId,
                completionHandler: { password in
                    
                    DispatchQueue.main.async {
                        
                        if let password = password {
                            print("✅ ClassroomDetailView: Password regeneration successful")

                            withAnimation {
                                classroomPassword = password
                                didRegenerate = true
                                isRegenerating = false
                            }
                            
                            // Reset success feedback after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                withAnimation {
                                    didRegenerate = false
                                }
                            }
                            
                        } else {
                            print("❌ ClassroomDetailView: Password regeneration failed")

                            withAnimation {
                                isRegenerating = false
                            }
                        }
                    }
                }
            )
        } label: {
            if !isRegenerating {
                
                Image(systemName: didRegenerate ?
                      "checkmark.circle.fill"
                      : "arrow.clockwise.circle.fill"
                )
                .transition(.scale)
                .foregroundColor(didRegenerate ? .green : .white)
                
            } else {
                
                ProgressView()
            }
        }
        .disabled(didRegenerate || isRegenerating)
    }
    
    // MARK: - Classroom Deletion Methods

    /// Handles classroom deletion for creators
    /// Performs complete removal of classroom and all associated data
    private func deleteThisClassroom() {
        print("🗑️ ClassroomDetailView: Starting classroom deletion process")
        
        withAnimation {
            isDeleting = true
            errorInDeleting = false
        }

        // Call DataManager to delete classroom
        DataManager.shared.deleteClassroom(
            classroomId: documentId,
            completionHandler: { success in
                
                DispatchQueue.main.async {
                    
                    if success {
                        
                        print("✅ ClassroomDetailView: Classroom deletion successful, dismissing view")

                        withAnimation {
                            isDeleting = false
                            dismiss()
                        }
                        
                    } else {
                        
                        print("❌ ClassroomDetailView: Classroom deletion failed")

                        withAnimation {
                            isDeleting = false
                            errorInDeleting = true
                        }
                        
                    }
                }
            }
        )
    }

    /// Handles unenrollment for students
    /// Removes current user from classroom membership
    private func unenrollFromClass() {
        print("🚪 ClassroomDetailView: Starting unenrollment process")

        withAnimation {
            isDeleting = true
            errorInDeleting = false
        }

        // Call DataManager to remove member
        DataManager.shared.removeMember(
            classroomId: documentId,
            userId: userId,
            completion: { success in
                
                DispatchQueue.main.async {
                    
                    if success {
                        print("✅ ClassroomDetailView: Unenrollment successful, dismissing view")

                        withAnimation {
                            isDeleting = false
                            dismiss()
                        }
                        
                    } else {
                        print("❌ ClassroomDetailView: Unenrollment failed")

                        withAnimation {
                            isDeleting = false
                            errorInDeleting = true
                        }
                        
                    }
                }
            }
        )
    }
    
    // MARK: - Utility Methods

    /// Dismisses the on-screen keyboard
    /// Used when user taps keyboard dismiss button or completes editing
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Preview

#Preview {
    ClassroomDetailView(
        userId: "3rNFDKJebENEfHqVFg475bJXb9j1",
        documentId: "gQatY3SaHOLK8vd9EUtl",
        // 150 chars max
        classroomName: "MPCS 51032 Advanced iOS Application Development (Autumn 2022) MPCS 51032 Advanced iOS Application Development (Autumn 2022) MPCS 51032 Advanced iOS De",
        createdAt: Date(),
        createdByName: "Abhyas Mall",
        isCreator: true,
        password: "548789B9-BFE2-4008-95B3-FC36105049D2"
    )
}
