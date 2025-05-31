//
//  ScoreView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/29/25.
//

import SwiftUI

/// Full-screen celebratory interface displayed immediately after quiz completion
struct ScoreView: View {
    
    // MARK: - Immutable Score Properties

    /// Student's final quiz score (number of correct answers)
    let score: Int
    
    /// Total number of questions in the completed quiz
    let total: Int
    
    /// Unique identifier of the student who completed the quiz
    let userId: String
    
    /// Unique identifier of the classroom containing the completed quiz
    let classroomId: String
    
    /// Unique identifier of the specific quiz that was completed
    let quizId: String
    
    /// Closure executed when score view is dismissed and data submission completes
    let onDismiss: () -> Void
    
    // MARK: - State Properties

    /// Loading state indicator for quiz statistics submission to Firebase
    @State private var isLoading: Bool = false
    
    /// Error state indicator for failed Firebase submission operations
    @State private var showError: Bool = false
    
    // MARK: - Body

    var body: some View {
        ZStack {
            
            // Immersive full-screen gradient background creating celebration atmosphere
            // Purple-to-pink gradient provides vibrant, engaging visual experience
            LinearGradient(
                colors: [.purple, .blue, .pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 30) {
                        
                        // Primary celebration message with emoji and shadow effects
                        // Immediately communicates successful quiz completion to student
                        Text("🎉 Quiz Completed!")
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .shadow(radius: 10)
                            .padding(.top, 40)
                        
                        // Central visual focus showing student's achievement with elegant design
                        // Large circular display with gradient background and shadow effects
                        ZStack {
                            
                            // Multi-layered circular background with gradient and stroke effects
                            // Creates depth and visual interest for score presentation
                            Circle()
                                .fill(
                                    RadialGradient(
                                        gradient: Gradient(colors: [.white.opacity(0.2), .white.opacity(0.05)]),
                                        center: .center,
                                        startRadius: 10,
                                        endRadius: 150
                                    )
                                )
                                .frame(width: 180, height: 180)
                                .shadow(radius: 20)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white.opacity(0.4), lineWidth: 4)
                                )
                            
                            // Prominently displayed numerical score with contextual information
                            // Large font size ensures immediate readability and impact
                            VStack {
                                Text("\(score)")
                                    .font(.system(size: 64, weight: .bold))
                                    .foregroundStyle(.white)
                                Text("out of \(total)")
                                    .font(.title3)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        
                        // Encouragement message based on student's performance percentage
                        // Provides positive reinforcement and motivation for continued learning
                        Text(scoreFeedback)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 30)
                            .transition(.opacity)
                        
                        // Main button for submitting quiz statistics and completing the quiz flow
                        // Handles loading states, error conditions, and successful submission
                        Button(action: {
                            
                            // Update UI to show loading state and clear previous errors
                            withAnimation {
                                isLoading = true
                                showError = false
                            }
                            
                            // Submit quiz statistics to Firebase Firestore
                            DataManager.shared.submitStatsForQuiz(
                                userId: userId,
                                classroomId: classroomId,
                                quizId: quizId,
                                newAttempt: Attempt(
                                    attemptDate: Date(),
                                    score: score,
                                    totalScore: total
                                ),
                                completionHandler: { success in
                                    print("📡 [ScoreView] Received submission response from DataManager")

                                    if let success = success {
                                        
                                        if success {
                                            
                                            // Submission successful - complete quiz flow
                                            print("✅ [ScoreView] Quiz statistics submission successful")

                                            withAnimation {
                                                isLoading = false
                                                onDismiss()
                                            }
                                            
                                        } else {
                                            
                                            // Submission failed with validation or database error
                                            print("❌ [ScoreView] Quiz statistics submission failed - validation error")

                                            withAnimation {
                                                isLoading = false
                                                showError = true
                                            }
                                            
                                        }
                                        
                                    } else {
                                        
                                        // Submission failed with validation or database error
                                        print("❌ [ScoreView] Quiz statistics submission failed - validation error")

                                        withAnimation {
                                            isLoading = false
                                            showError = true
                                        }
                                        
                                    }
                                }
                            )
                        }) {
                            
                            // Dynamic button content based on submission state
                            // Provides clear feedback about current operation status
                            Group {
                                
                                // Loading state with progress indicator
                                if isLoading {
                                    HStack {
                                        ProgressView()
                                        Text("Loading...")
                                    }
                                    
                                } else if showError {
                                    
                                    // Error state with retry messaging
                                    Label(
                                        "Failed to submit. Tap to retry.",
                                        systemImage: "exclamationmark.triangle.fill"
                                    )
                                    
                                } else {
                                    
                                    // Normal state with completion messaging
                                    Text("Done")
                                }
                            }
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                isLoading ? Color.gray.opacity(0.8) : Color.white.opacity(0.15)
                            )
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                            )
                        }
                        .disabled(isLoading)
                        .padding(.horizontal, 5)
                        .foregroundStyle(.white)
                        
                        // Alternative dismissal option for users who want to skip submission
                        // Provides escape route while maintaining primary action emphasis
                        Button {
                            onDismiss()
                        } label: {
                            Text("Dismiss")
                                .font(.headline)
                                .padding()
                                .frame(maxWidth: .infinity)
                        }
                        .background(
                            Color.gray.opacity(0.25)
                        )
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.gray, lineWidth: 3.5)
                        )
                        .padding(.horizontal, 5)
                        .foregroundStyle(.white)
                        
                    }
                    .frame(maxWidth: .infinity, minHeight: geometry.size.height)
                    .padding()
                }
            }
        }
    }
    
    // MARK: - Score Feedback Computation

    /// Generates encouraging feedback message based on student's quiz performance
    private var scoreFeedback: String {
        let percentage = Double(score) / Double(total)
        switch percentage {
        case 1.0:
            return "Perfect score! 🌟"
        case 0.8...0.99:
            return "Great job! 🥳"
        case 0.5..<0.8:
            return "Nice try! 👍"
        default:
            return "Keep practicing! 🔄"
        }
    }
}

// MARK: - Preview

#Preview {
    ScoreView(
        score: 8,
        total: 10,
        userId: "3rNFDKJebENEfHqVFg475bJXb9j1",
        classroomId: "gQatY3SaHOLK8vd9EUtl",
        quizId: "1f3OThYT1HzBjy1USPLQ",
        onDismiss: {}
    )
}
