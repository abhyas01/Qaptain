//
//  MemberCell.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/30/25.
//

import SwiftUI

struct MemberCell: View {
    
    let member: Member
    let isRemovable: Bool
    let classroomId: String
    let onRemoval: (_: String) -> Void

    @State private var isLoading: Bool = false
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(member.name)
                    .font(.headline)
                Text(member.email)
                    .font(.caption)
                    .foregroundColor(.secondary)
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
        .overlay {
            if isLoading {
                VStack {
                    ProgressView()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func removeMember(_ member: Member) {
        withAnimation {
            isLoading = true
        }
        DataManager.shared.removeMember(classroomId: classroomId, userId: member.userId) { success in
            DispatchQueue.main.async {
                withAnimation {
                    isLoading = false
                    if success {
                        onRemoval(member.userId)
                    }
                }
            }
        }
    }
}

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
