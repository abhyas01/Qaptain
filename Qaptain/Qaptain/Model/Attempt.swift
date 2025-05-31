//
//  Attempt.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/28/25.
//

import Foundation

/// Represents a single quiz attempt by a student with score and timing information
/// Stores essential data for tracking student performance and late submission detection
/// Used within QuizStat model to maintain complete history of all student attempts
/// Implements Codable for Firestore serialization and Hashable for SwiftUI list operations
struct Attempt: Codable, Hashable {
    var attemptDate: Date
    var score: Int
    var totalScore: Int
}
