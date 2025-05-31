//
//  Classroom.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/23/25.
//

import FirebaseFirestore

/// Represents a classroom entity in the Qaptain application with teacher and student management
/// Core model for organizing quizzes, members, and educational content within isolated groups
/// Implements Firestore integration with automatic ID management and timestamp handling
/// Used throughout the app for classroom listing, management, and access control
struct Classroom: Identifiable, Codable {
    @DocumentID var id: String?
    var classroomName: String
    @ServerTimestamp var createdAt: Date?
    var createdByName: String
    var password: String
}
