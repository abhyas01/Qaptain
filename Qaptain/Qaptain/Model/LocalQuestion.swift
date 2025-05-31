//
//  LocalQuestion.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/30/25.
//

import Foundation

/// Represents a quiz question during the creation/editing process before Firestore submission
/// Used in quiz creation forms with real-time validation and dynamic option management
/// Converts to Firestore format via firestoreData property for database storage
/// Provides client-side validation to prevent invalid questions from being submitted
struct LocalQuestion: Identifiable {
    
    /// Unique identifier for SwiftUI list operations and form management
    let id = UUID()
    
    /// The main question text that students will see and answer
    var prompt: String = ""
    
    /// Array of possible answer choices for this multiple-choice question
    /// Dynamically managed during creation, filtered to remove empty options
    var options: [String] = [""]
    
    /// The correct answer selected from the available options
    /// Must match exactly one of the provided options for question to be valid
    var answer: String = ""

    // MARK: - Computed Properties for Validation

    /// Cleaned question prompt with whitespace removed for validation
    /// Used to check if question has meaningful content before submission
    var trimmedPrompt: String {
        return prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Filtered array of non-empty answer options for validation and submission
    /// Removes empty strings that might be added during dynamic option creation
    var trimmedOptions: [String] {
        let trimmedOptions = options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return trimmedOptions.filter { !$0.isEmpty }
    }
    
    /// Cleaned correct answer with whitespace removed for validation
    /// Used to verify answer matches one of the available options
    var trimmedAnswer: String {
        return answer.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    /// Validation status indicating if question is ready for submission
    /// Checks that prompt exists, options are available, and answer is valid
    var isValid: Bool {
        return !trimmedPrompt.isEmpty && !trimmedOptions.isEmpty && trimmedOptions.contains(trimmedAnswer)
    }

    /// Firestore-compatible data structure for database storage
    /// Converts local question format to format expected by Firestore collections
    var firestoreData: [String: Any] {
        [
            "question": trimmedPrompt,
            "options": trimmedOptions,
            "answer": trimmedAnswer
        ]
    }
}
