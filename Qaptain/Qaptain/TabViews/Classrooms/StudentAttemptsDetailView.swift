//
//  StudentAttemptsDetailView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/30/25.
//

import SwiftUI

/// Comprehensive drill-down view displaying detailed quiz attempt history for a specific student
struct StudentAttemptsDetailView: View {
    
    // MARK: - Properties

    /// Complete quiz statistics object for the specific student being reviewed
    let stat: QuizStat
    
    /// Quiz deadline used for late submission detection and visual indicators
    let deadline: Date
    
    // MARK: - Computed Properties

    /// Student's quiz attempts organized chronologically with most recent first
    private var sortedAttempts: [Attempt] {
        return stat.attempts.sorted(by: { $0.attemptDate > $1.attemptDate })
    }
    
    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                // Prominent header section displaying student information with professional styling
                // Uses material design background and profile icon for clear identification
                VStack(spacing: 6) {
                    HStack {
                        
                        // Large profile icon providing visual identification anchor
                        // Orange theming maintains app consistency and visual hierarchy
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.orange)
                        
                        // Student name and email display with proper typography hierarchy
                        // Left-aligned for natural reading flow and information scanning
                        VStack(alignment: .leading, spacing: 2) {
                            Text(stat.name)
                                .font(.title2)
                                .fontWeight(.bold)
                            Text(stat.email)
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        
                    }
                    .padding()
                }
                .background(
                    RoundedRectangle(cornerRadius: 18)
                        .fill(.ultraThinMaterial)
                        .shadow(radius: 3, y: 2)
                )
                .padding(.horizontal)
                .padding(.top, 10)
                .padding(.bottom, 5)
                
                // Main content area displaying student's complete quiz attempt history
                // Organized in list format with clear section headers and attempt details
                List {
                    Section {
                        
                        // Display appropriate message when student hasn't attempted the quiz
                        // Provides clear feedback to teachers about student engagement status
                        if stat.attempts.isEmpty {
                            Text("No attempts yet.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(Color.clear)
                            
                        } else {
                            
                            // Chronological list of quiz attempts with detailed timing and scoring information
                            // Each attempt shows date, time, score, and late submission status
                            ForEach(sortedAttempts, id: \.self) { attempt in
                                
                                // Calculate late submission status for this specific attempt
                                let isLate = attempt.attemptDate > deadline
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    
                                    // Top section showing attempt timestamp with conditional late submission warning
                                    // Red coloring for late submissions draws immediate teacher attention
                                    HStack {
                                        Text(attempt.attemptDate.formatted(date: .abbreviated, time: .shortened))
                                            .font(.headline)
                                            .foregroundStyle(isLate ? .red : .secondary)
                                        
                                        if isLate {
                                            Spacer()
                                            
                                            // Prominent warning badge for late submissions
                                            // Red background with white text ensures maximum visibility
                                            Text("LATE")
                                                .font(.caption)
                                                .fontWeight(.semibold)
                                                .foregroundStyle(.red)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(.red.opacity(0.1))
                                                .cornerRadius(6)
                                        } else {
                                            
                                            Spacer()
                                            
                                        }
                                    }
                                    
                                    // Clear presentation of attempt score with consistent formatting
                                    // Bold typography emphasizes performance data for teacher review
                                    Text("Score: \(attempt.score)/\(attempt.totalScore)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.primary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                    } header: {
                        
                        // Section header providing clear context for attempt history
                        // Orange theming maintains visual consistency with app design
                        Text("Attempts")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                    }
                }
                .listStyle(.plain)
            }
            
            // Navigation Configuration
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("Student Attempts")
                    }
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.orange)
                    .fontWeight(.bold)
                }
            }
            .background(
                Color(
                    .systemGroupedBackground
                )
            )
        }
    }
}

// MARK: - Preview

#Preview {
    StudentAttemptsDetailView(
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
        deadline: Date().addingTimeInterval(-2500)
    )
}
