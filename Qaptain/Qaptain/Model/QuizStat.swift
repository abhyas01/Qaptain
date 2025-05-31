//
//  QuizStat.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/28/25.
//

import FirebaseFirestore

/// Represents comprehensive statistics for a student's performance on a specific quiz
/// Stores complete attempt history, timing data, and student identification information
/// Used for grade tracking, performance analytics, and progress monitoring
/// Links student accounts to quiz performance with detailed attempt tracking
struct QuizStat: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var email: String
    var name: String
    var lastAttemptDate: Date
    var attempts: [Attempt]
}
