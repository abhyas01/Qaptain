//
//  ClassroomsCell.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/24/25.
//

import SwiftUI

struct ClassroomsCell: View {
    
    let classroomName: String
    let createdByName: String
    let createdAt: Date?
    
    var body: some View {
        VStack {
            Text(classroomName)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
                .multilineTextAlignment(
                    .leading
                )
            
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
            
            HStack {
                Spacer()
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

#Preview {
    ClassroomsCell(
        classroomName: "MPCS 5031: Advanced iOS Development",
        createdByName: "T.A. Binkowski",
        createdAt: Date()
    )
}
