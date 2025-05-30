//
//  ScoreView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/29/25.
//

import SwiftUI

struct ScoreView: View {
    
    let score: Int
    let total: Int
    let userId: String
    let classroomId: String
    let quizId: String
    
    let onDismiss: () -> Void
    
    @State private var isLoading: Bool = false
    @State private var showError: Bool = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [.purple, .blue, .pink],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 30) {
                        Text("🎉 Quiz Completed!")
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .shadow(radius: 10)
                            .padding(.top, 40)
                        
                        ZStack {
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
                            
                            VStack {
                                Text("\(score)")
                                    .font(.system(size: 64, weight: .bold))
                                    .foregroundStyle(.white)
                                Text("out of \(total)")
                                    .font(.title3)
                                    .foregroundStyle(.white.opacity(0.8))
                            }
                        }
                        
                        Text(scoreFeedback)
                            .font(.title2)
                            .multilineTextAlignment(.center)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 30)
                            .transition(.opacity)
                        
                        Button(action: {
                            
                            withAnimation {
                                isLoading = true
                                showError = false
                            }
                            
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
                                    if let success = success {
                                        
                                        if success {
                                            
                                            withAnimation {
                                                isLoading = false
                                                onDismiss()
                                            }
                                            
                                        } else {
                                            
                                            withAnimation {
                                                isLoading = false
                                                showError = true
                                            }
                                            
                                        }
                                        
                                    } else {
                                        
                                        withAnimation {
                                            isLoading = false
                                            showError = true
                                        }
                                        
                                    }
                                }
                            )
                        }) {
                            Group {
                                if isLoading {
                                    HStack {
                                        ProgressView()
                                        Text("Loading...")
                                    }
                                    
                                } else if showError {
                                    
                                    Label(
                                        "Failed to submit. Tap to retry.",
                                        systemImage: "exclamationmark.triangle.fill"
                                    )
                                    
                                } else {
                                    
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
