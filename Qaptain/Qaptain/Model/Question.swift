//
//  Question.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/29/25.
//

import FirebaseFirestore

/// Represents a quiz question stored in Firestore with answer tracking capabilities
/// Core model for quiz content delivery and student response collection
/// Includes both persistent data (from database) and transient UI state (student selection)
/// Used during quiz taking, review, and administrative question management
struct Question: Identifiable, Codable {
    @DocumentID var id: String?
    var question: String
    var options: [String]
    var answer: String
    
    /// Local UI-only property
    var tappedAnswer: String = ""
    
    /// Defines which properties are included in Firestore serialization
    enum CodingKeys: String, CodingKey {
        case id
        case question
        case options
        case answer
    }
}
