//
//  QuizStatCell.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/30/25.
//

import SwiftUI

/// Reusable SwiftUI component that displays individual student quiz statistics in a card format
struct QuizStatCell: View {
    
    // MARK: - Properties

    /// Complete quiz statistics for a specific student including all attempts and metadata
    let stat: QuizStat
    
    /// Official quiz deadline used to determine if submissions are late
    let deadline: Date

    // MARK: - Computed Properties

    /// Determines if the student's last attempt was submitted after the quiz deadline
    private var isLateSubmission: Bool {
        return stat.lastAttemptDate > deadline
    }
    
    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            
            // Top section displaying student name prominently and email for additional identification
            // Uses HStack to balance name (left) and email (right) for optimal information density
            HStack {
                Text(stat.name)
                    .font(.headline)
                Spacer()
                Text(stat.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Displays the student's most recent quiz attempt with date, time, and score
            // Handles the case where student hasn't attempted the quiz yet
            // Uses color coding to immediately indicate late vs on-time submissions
            if let lastAttempt = stat.attempts.sorted(by: { $0.attemptDate > $1.attemptDate }).first {
                HStack(alignment: .center) {
                    
                    // Left side showing when the last attempt was made
                    // Color changes to red for late submissions to draw attention
                    VStack(alignment: .leading) {
                        Text("Last Attempt:")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        
                        Text(lastAttempt.attemptDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.footnote)
                            .foregroundStyle(isLateSubmission ? .red : .primary)
                    }
                    
                    Spacer()
                    
                    // Right side showing the student's score with visual feedback
                    // Green for on-time submissions, red for late submissions
                    // Format: "Score: X/Y" for clear understanding
                    Text("Score: \(lastAttempt.score)/\(lastAttempt.totalScore)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(isLateSubmission ? .red : .green)
                }
            } else {
                
                // Fallback display when student hasn't attempted the quiz
                // Provides clear feedback about missing attempts
                Text("No attempts yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    QuizStatCell(
        stat: QuizStat(
            userId: "user123",
            email: "student@example.com",
            name: "Alex Johnson",
            lastAttemptDate: Date().addingTimeInterval(-1800),
            attempts: [
                Attempt(
                    attemptDate: Date().addingTimeInterval(-1800),
                    score: 7,
                    totalScore: 10
                ),
                Attempt(
                    attemptDate: Date().addingTimeInterval(-36000),
                    score: 8,
                    totalScore: 10
                ),
                Attempt(
                    attemptDate: Date().addingTimeInterval(-172800),
                    score: 5,
                    totalScore: 10
                )
            ]
        ),
        deadline: Date().addingTimeInterval(-1500)
    )
}
