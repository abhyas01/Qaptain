//
//  StudentAttemptsDetailView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/30/25.
//

import SwiftUI

struct StudentAttemptsDetailView: View {
    
    let stat: QuizStat
    let deadline: Date
    
    private var sortedAttempts: [Attempt] {
        return stat.attempts.sorted(by: { $0.attemptDate > $1.attemptDate })
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                
                VStack(spacing: 6) {
                    HStack {
                        Image(systemName: "person.crop.circle.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.orange)
                        
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
                
                List {
                    Section {
                        
                        if stat.attempts.isEmpty {
                            Text("No attempts yet.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(Color.clear)
                            
                        } else {
                            ForEach(sortedAttempts, id: \.self) { attempt in
                                
                                let isLate = attempt.attemptDate > deadline
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(attempt.attemptDate.formatted(date: .abbreviated, time: .shortened))
                                            .font(.headline)
                                            .foregroundStyle(isLate ? .red : .secondary)
                                        
                                        if isLate {
                                            Spacer()
                                            
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
                                    Text("Score: \(attempt.score)/\(attempt.totalScore)")
                                        .font(.subheadline)
                                        .fontWeight(.bold)
                                        .foregroundStyle(.primary)
                                }
                                .padding(.vertical, 8)
                            }
                        }
                        
                    } header: {
                        Text("Attempts")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.orange)
                    }
                }
                .listStyle(.plain)
            }
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
