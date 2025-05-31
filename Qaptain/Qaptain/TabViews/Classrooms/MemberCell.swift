//
//  MemberCell.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/30/25.
//

import SwiftUI

/// Reusable SwiftUI component for displaying individual classroom members in list views
struct MemberCell: View {
    
    // MARK: - Properties

    /// The member data model containing user information and classroom role
    let member: Member
    
    /// Flag indicating whether this member can be removed by the current user
    let isRemovable: Bool
    
    /// The ID of the classroom from which the member might be removed
    let classroomId: String
    
    /// Callback executed when member removal is successful
    let onRemoval: (_: String) -> Void

    // MARK: - State Properties

    /// Flag indicating whether a member removal operation is in progress
    @State private var isLoading: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        HStack {
            
            // Member Information Section
            VStack(alignment: .leading, spacing: 5) {
                
                // Primary member name display
                Text(member.name)
                    .font(.headline)
                
                // Secondary email address display
                Text(member.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Role indicator with color coding
                if member.isCreator {
                    Text("Teacher")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                } else {
                    Text("Student")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            // Removal Button Section
            if isRemovable {
                Button(role: .destructive) {
                    removeMember(member)
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.red)
                }
                .buttonStyle(BorderlessButtonStyle())
            }
        }
        .padding(.vertical, 8)
        
        // Loading Overlay
        .overlay {
            if isLoading {
                VStack {
                    ProgressView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    // MARK: - Member Removal Logic
    
    /// Initiates the member removal process through DataManager
    /// - Parameter member: The member to be removed from the classroom
    private func removeMember(_ member: Member) {
        
        // Set loading state to prevent duplicate removal attempts
        withAnimation {
            isLoading = true
        }
        
        DataManager.shared.removeMember(classroomId: classroomId, userId: member.userId) { success in

            print("📡 [MemberCell] Received removal response from DataManager: \(success)")

            DispatchQueue.main.async {
                
                // Clear loading state
                withAnimation {
                    isLoading = false
                    
                    // Handle removal result
                    if success {
                        print("🎉 [MemberCell] Member removal successful for: '\(member.name)'")
                        onRemoval(member.userId)
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MemberCell(
        member: Member(
            userId: "2342342qdasd",
            email: "abhyas@uchicago.edu",
            name: "Abhyas Mall",
            isCreator: false,
            classroomCreatedAt: Date()
        ),
        isRemovable: true,
        classroomId: "98asfiushadf"
    ) {_ in}
}
