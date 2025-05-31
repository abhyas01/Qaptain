//
//  ClassroomsCell.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/24/25.
//

import SwiftUI

/// A reusable SwiftUI view component that displays classroom information in a card-like format
struct ClassroomsCell: View {
    
    // MARK: - Properties

    /// The display name of the classroom (e.g., "MPCS 51032: Advanced iOS Development")
    let classroomName: String
    
    /// The full name of the user who created this classroom (teacher/instructor name)
    let createdByName: String
    
    /// Optional timestamp when the classroom was created - used for sorting and display
    let createdAt: Date?
    
    // MARK: - View Body

    var body: some View {
        VStack {
            
            // Primary classroom name display
            Text(classroomName)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .multilineTextAlignment(
                    .leading
                )
            
            // Secondary creator/teacher name display
            Text(createdByName)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .multilineTextAlignment(
                    .leading
                )
            
            // Creation date display section
            HStack {
                Spacer()
                
                // Handle optional creation date with fallback text
                Text(
                    createdAt?.formatted(
                        date: .abbreviated,
                        time: .shortened
                    ) ?? "Unknown Date"
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview Provider

#Preview {
    ClassroomsCell(
        classroomName: "MPCS 5031: Advanced iOS Development",
        createdByName: "Abhyas",
        createdAt: Date()
    )
}
