//
//  QuizStatCell.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/30/25.
//

import SwiftUI

struct QuizStatCell: View {
    let stat: QuizStat
    let deadline: Date

    private var isLateSubmission: Bool {
        return stat.lastAttemptDate > deadline
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(stat.name)
                    .font(.headline)
                Spacer()
                Text(stat.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let lastAttempt = stat.attempts.sorted(by: { $0.attemptDate > $1.attemptDate }).first {
                HStack(alignment: .center) {
                    VStack(alignment: .leading) {
                        Text("Last Attempt:")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                        
                        Text(lastAttempt.attemptDate.formatted(date: .abbreviated, time: .shortened))
                            .font(.footnote)
                            .foregroundStyle(isLateSubmission ? .red : .primary)
                    }
                    Spacer()
                    
                    Text("Score: \(lastAttempt.score)/\(lastAttempt.totalScore)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(isLateSubmission ? .red : .green)
                }
            } else {
                Text("No attempts yet.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}


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
