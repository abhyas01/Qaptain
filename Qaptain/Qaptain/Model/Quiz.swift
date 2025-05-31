//
//  Quiz.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/27/25.
//

import FirebaseFirestore

/// Represents a quiz entity with metadata, timing, and Firestore integration
/// Core model for quiz management containing essential information for scheduling and identification
/// Links to separate collections for questions and student statistics
/// Used throughout the app for quiz listing, management, and access control
struct Quiz: Identifiable, Codable {
    @DocumentID var id: String?
    @ServerTimestamp var createdAt: Date?
    var deadline: Date
    var quizName: String
}
