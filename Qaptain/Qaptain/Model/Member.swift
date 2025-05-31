//
//  Member.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/27/25.
//

import FirebaseFirestore

/// Represents a user's membership in a specific classroom with role
/// Links user accounts to classroom participation
/// Used for member lists, permission checks, and classroom administration
struct Member: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var email: String
    var name: String
    var isCreator: Bool
    var classroomCreatedAt: Date
}
