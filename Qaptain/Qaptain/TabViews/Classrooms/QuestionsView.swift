//
//  QuestionsView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/29/25.
//

import SwiftUI

/// Full-screen immersive quiz-taking interface that presents questions one at a time
struct QuestionsView: View {
    
    // MARK: - Immutable Properties
    
    /// Unique identifier of the classroom containing this quiz
    let classroomId: String
    
    /// Unique identifier of the user taking the quiz
    let userId: String
    
    /// Unique identifier of the quiz being taken
    let quizId: String
    
    /// Display name of the quiz shown in the header
    let quizName: String
    
    // MARK: - Mutable Quiz State
    
    /// Array of all questions in the quiz with their current state
    @State var questions: [Question]
    
    // MARK: - Callback Functions
    
    /// Callback function executed when the quiz session ends
    let onDismiss: () -> Void
    
    // MARK: - Environment Dependencies
    
    /// SwiftUI environment value for programmatically dismissing this full-screen view
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Quiz Progress State
    
    /// Visual progress indicator showing completion percentage (0.0 to 1.0)
    @State private var progress: CGFloat = 0
    
    /// Index of the currently displayed question (0-based)
    @State private var currentIndex: Int = 0
    
    /// Running total of correct answers accumulated during the quiz
    @State private var score: Int = 0
    
    /// Controls the presentation of the final score screen
    @State private var presentScore: Bool = false
    
    // MARK: - Body
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                
                // Close button allowing user to exit quiz before completion
                // Positioned at top-left for easy access and follows iOS conventions
                VStack(spacing: 20) {
                    
                    Button {
                        print("❌ [QuestionsView] User tapped close button - dismissing quiz")
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Quiz title display with proper styling and line limiting
                    Text(quizName)
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    
                    // Progress Bar Section
                    // Animated progress bar showing quiz completion status
                    // Uses GeometryReader to create responsive width-based progress indication
                    // Background and foreground layers create smooth visual progress feedback
                    GeometryReader {
                        let size = $0.size
                        
                        ZStack(alignment: .leading) {
                            
                            // Background track for progress bar
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.black.opacity(0.2))
                            
                            // Animated foreground progress indicator
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.orange)
                                .frame(width: progress * size.width, alignment: .leading)
                        }
                    }
                    .frame(height: 35)
                    
                    // Question Display Section
                    // Current question presentation with smooth transition animations
                    // Only shows the question at currentIndex to maintain focus
                    // Uses transition effects for smooth question changes
                    Group {
                        ForEach(questions.indices, id: \.self) { index in
                            if currentIndex == index {
                                questionView(questions[currentIndex])
                                    .transition(.opacity)
                            }
                        }
                    }
                    .padding(.horizontal, -20)
                    
                    // Navigation Button Section
                    // Primary navigation button for advancing through quiz
                    // Text changes to "Finish" on the last question
                    // Disabled until user selects an answer for current question
                    Button {
                        if currentIndex < (questions.count - 1) {
                            
                            // Advance to next question with smooth animation
                            withAnimation(.easeInOut(duration: 0.25)) {
                                currentIndex += 1
                            }
                            
                            // Update progress bar to reflect new position
                            withAnimation {
                                progress = (CGFloat(currentIndex) + 1) / CGFloat(questions.count)
                            }
                            
                        } else if currentIndex == questions.count - 1 {
                            print("🏁 [QuestionsView] User finished last question - presenting final score")
                            
                            // Present the Score Sheet
                            presentScore = true
                        }
                    } label: {
                        HStack {
                            Text(
                                currentIndex == questions.count - 1 ?
                                "Finish" :
                                    "Next Question"
                            )
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .fontWeight(.bold)
                            .padding(.vertical, 8)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(
                        currentIndex == questions.count - 1 ?
                            .green :
                                .none
                    )
                    
                    // Button disabled until user selects an answer
                    .disabled(questions[currentIndex].tappedAnswer == "")
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .frame(minHeight: geometry.size.height)
                .frame(maxWidth: .infinity, alignment: .top)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(Color(.systemGray2))
            
            // Score Presentation
            // Full-screen score presentation when quiz is completed
            // Passes final score and quiz metadata to ScoreView
            // Handles score submission to Firebase and view dismissal
            .fullScreenCover(isPresented: $presentScore) {
                ScoreView(
                    score: score,
                    total: questions.count,
                    userId: userId,
                    classroomId: classroomId,
                    quizId: quizId
                ) {
                    
                    print("✅ [QuestionsView] Score view dismissed - cleaning up and returning to previous view")
                    dismiss()
                    onDismiss()
                }
            }
        }
    }
    
    // MARK: - Question Display Methods
    
    /// Creates the visual representation of a single quiz question
    /// Handles question text display, option presentation, and answer selection logic
    /// Provides immediate visual feedback when answers are selected
    ///
    /// - Parameter question: The question object to display
    /// - Returns: A SwiftUI view containing the complete question interface
    ///
    /// Features:
    /// - Question number indicator for user orientation
    /// - Large, readable question text
    /// - Interactive option buttons with color-coded feedback
    /// - Answer locking mechanism to prevent changes after selection
    /// - Visual highlighting of correct/incorrect answers
    private func questionView(_ question: Question) -> some View {
        VStack(spacing: 20) {
            
            // Question Header
            // Question number indicator showing current position in quiz
            // Helps users understand their progress through the question set
            Text("Question \(currentIndex + 1)/\(questions.count)")
                .font(.callout)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity,alignment: .leading)
            
            // Main question text display with emphasis styling
            // Large, bold text ensures readability and focus
            Text(question.question)
                .font(.title3)
                .fontWeight(.bold)
            
            // Answer Options Section
            // Vertical stack of answer option buttons
            // Each option is styled based on selection state and correctness
            VStack(spacing: 10) {
                ForEach(Array(question.options.enumerated()), id: \.offset) { idx, option in
                    
                    optionView(option, backgroundColor(at: idx, in: question))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            
                            // Prevent answer changes after selection (answer locking)
                            guard questions[currentIndex].tappedAnswer == "" else { return }
                            
                            // Check if selected answer is correct and update score
                            if question.answer == option {
                                score += 1
                            }
                            
                            // Lock in the user's answer selection
                            withAnimation {
                                questions[currentIndex].tappedAnswer = option
                            }
                        }
                }
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }
    
    // MARK: - Answer Option Styling Methods
    
    /// Creates the visual representation of a single answer option
    /// Applies dynamic styling based on selection state and correctness
    ///
    /// - Parameters:
    ///   - option: The text of the answer option
    ///   - tint: The color to apply based on selection/correctness state
    /// - Returns: A styled view representing the answer option
    private func optionView(_ option: String, _ tint: Color) -> some View {
        Text(option)
            .fontWeight(.bold)
            .foregroundStyle(Color(tint))
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 15)
            .padding(.vertical, 20)
            .background {
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .stroke(
                    tint,
                    lineWidth: tint != .primary ? 6 : 2
                )
                .fill(
                    tint != .primary ? .white : .clear
                )
            }
    }
    
    /// Determines the background color for an answer option cell at a given index in a quiz question,
    /// based on the user's selection and whether the option is correct or incorrect.
    ///
    /// - Parameters:
    ///   - index: The index of the option within the `question.options` array.
    ///   - question: The `Question` object containing the options, the correct answer, and the tapped answer.
    /// - Returns: A `Color` indicating the visual feedback for the option at the given index (`.primary`, `.green`, or `.red`).
    ///
    /// Logic:
    /// - If no answer has been selected yet, all options are colored `.primary`.
    /// - If the tapped answer is correct (matches the correct answer value):
    ///     - Only the tapped cell (matching both value and index) is colored `.green`.
    ///     - All other options remain `.primary`.
    /// - If the tapped answer is incorrect:
    ///     - All option cells matching the correct answer value are colored `.green`.
    ///     - Only the tapped cell (matching both value and index) is colored `.red`.
    ///     - All other options remain `.primary`.
    ///
    /// Note:
    /// - This logic ensures that when duplicate option values are present, only the specific cell the user tapped (by index) is highlighted red or green for correct selection, and all cells with the correct answer are highlighted green for incorrect selections.
    private func backgroundColor(at index: Int, in question: Question) -> Color {
        let tapped = question.tappedAnswer
        let answer = question.answer
        
        // No answer selected yet
        if tapped == "" {
            return .primary
        }
        
        // If tapped is correct: highlight only the tapped cell green
        if tapped == answer {
            
            // Only the tapped cell (by index and value) is green
            if question.options[index] == tapped  {
                return .green
            } else {
                return .primary
            }
            
        } else {
            
            // Tapped is incorrect: highlight tapped cell red, all correct cells green
            if question.options[index] == answer {
                return .green
            } else if question.options[index] == tapped  {
                return .red
            } else {
                return .primary
            }
        }
    }
}

// MARK: - Preview

#Preview {
    QuestionsView(
        classroomId: "gQatY3SaHOLK8vd9EUtl",
        userId: "3rNFDKJebENEfHqVFg475bJXb9j1",
        quizId: "1f3OThYT1HzBjy1USPLQ",
        quizName: "Module - Judy and the other three were the first two I had g",
        questions: Array(
            repeating: Question(
                id: "sTJgp2PIuUdMpdPf7fmU",
                question: "When was Obi-Wan Kenobi born?",
                options: [
                    "58 BBY",
                    "58 BBY",
                    "None of the above"
                ],
                answer: "58 BBY",
                tappedAnswer: ""
            ),
            count: 5
        )
    ) {}
}
