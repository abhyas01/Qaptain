//
//  QuizDetailView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/28/25.
//

import SwiftUI

/// Comprehensive quiz management and interaction view that serves different functions based on user role
/// This view acts as the central hub for all quiz-related operations, providing different capabilities
/// for teachers (quiz creators) versus students (quiz takers).
struct QuizDetailView: View {
    
    // MARK: - Immutable Properties

    /// Unique identifier of the classroom containing this quiz
    let classroomId: String
    
    /// Unique identifier of the current user viewing this quiz
    let userId: String
    
    /// Unique identifier of the quiz being displayed
    let quizId: String
    
    // MARK: - Mutable Quiz Data

    /// Complete quiz object with metadata, deadline, and name information
    @State var quiz: Quiz
    
    // MARK: - Quiz Metadata
    
    /// Date when the quiz was originally created
    let quizCreatedAt: Date
    
    /// Boolean indicating if current user is the quiz creator
    let isCreator: Bool
    
    // MARK: - Environment Dependencies

    /// SwiftUI environment value for programmatically dismissing this view
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - Quiz Editing State

    /// Current quiz name being edited (working copy during editing session)
    @State private var quizName: String
    
    /// Current quiz deadline being edited (working copy during editing session)
    @State private var deadline: Date
    
    /// Flag indicating whether the quiz is currently in editing mode
    /// Switches UI between display and editing interfaces
    @State private var isEditing = false
    
    /// Loading state for quiz save operations
    @State private var isSaving = false
    
    /// Flag indicating whether to show validation error alerts
    @State private var showError = false

    // MARK: - Quiz Attempts State

    /// Array of all user's attempts for this quiz
    @State private var attempts: [Attempt] = []
    
    /// Loading state for quiz statistics fetching
    @State private var isLoading = true
    
    /// Error state for quiz statistics fetching failures
    @State private var errorInFetchingStat = false

    // MARK: - Quiz Questions State

    /// Array of all questions in this quiz
    @State private var questions: [Question] = []
    
    /// Loading state for quiz questions fetching
    @State private var isDownloadingQuestions: Bool = false
    
    /// Error state for questions download failures
    @State private var didFailDownloadingQuestions: Bool = false
    
    /// Flag indicating whether the quiz has no questions
    @State private var isQuestionArrayEmpty: Bool = false
    
    /// Controls full-screen presentation of the quiz-taking interface
    @State private var startQuiz: Bool = false
    
    // MARK: - Quiz Deletion State

    /// Loading state for quiz deletion operations
    @State private var isDeleting: Bool = false
    
    /// Error state for quiz deletion failures
    @State private var errorInDeleting: Bool = false
    
    /// Controls display of quiz deletion confirmation dialog
    @State private var deleteAlert: Bool = false
    
    // MARK: - Computed Properties

    /// User's quiz attempts sorted by most recent first
    private var sortedAttempts: [Attempt] {
        attempts.sorted(by: { $0.attemptDate > $1.attemptDate })
    }
    
    /// Boolean indicating whether the quiz deadline has passed
    private var hasDeadlinePassed: Bool {
        return Date() > deadline
    }
    
    /// Cleaned and validated version of the quiz name during editing
    private var cleanedQuizName: String {
        let trimmedQuizName = quizName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let components = trimmedQuizName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return components.joined(separator: " ")
    }
    
    /// Validation status for quiz editing operations
    private var isUpdationValid: Bool {
        
        let nameCount = cleanedQuizName.count
        return (
            (nameCount >= 4 && nameCount <= 60)
            &&
            (deadline > quizCreatedAt)
        )
    }
    
    // MARK: - Initialization

    init(
        classroomId: String,
        userId: String,
        quizId: String,
        quiz: Quiz,
        quizCreatedAt: Date,
        isCreator: Bool
    ) {
        self.classroomId = classroomId
        self.userId = userId
        self.quizId = quizId
        self.quiz = quiz
        self.quizCreatedAt = quizCreatedAt
        self.isCreator = isCreator

        _quizName = State(initialValue: quiz.quizName)
        _deadline = State(initialValue: quiz.deadline)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 70) {
                        
                        // Header Section
                        headerSection
                        
                        // Statistics Section
                        if isLoading {
                            
                            // Loading state for quiz statistics
                            // Shows progress indicator while fetching user's attempt data
                            ProgressView("Fetching Attempts...")
                                .progressViewStyle(
                                    CircularProgressViewStyle(
                                        tint: .orange
                                    )
                                )
                            
                        } else if errorInFetchingStat {
                            
                            // Error state with retry functionality
                            // Displayed when statistics fetching fails
                            retrySection
                            
                        } else {
                            
                            // Attempt history display
                            // Shows user's quiz attempts if any exist
                            if !attempts.isEmpty {
                                
                                attemptList
                                
                            }
                        }
                        
                        // Action Buttons Section
                        primaryActionButton
                        
                        // Quiz Information Section
                        quizRulesSection
                    }
                    .padding()
                    .frame(minHeight: geometry.size.height)
                }
            }
            
            // Modal Presentations
            // Full-screen quiz taking interface
            // Presents QuestionsView when user starts the quiz
            .fullScreenCover(isPresented: $startQuiz) {
                QuestionsView(
                    classroomId: classroomId,
                    userId: userId,
                    quizId: quizId,
                    quizName: quiz.quizName,
                    questions: questions
                ) {
                    print("🔄 [QuizDetailView] Quiz completed - refreshing statistics")
                    getStats()
                }
            }
            
            // Navigation Configuration
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "doc.text")
                        Text(quiz.quizName)
                    }
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.orange)
                    .fontWeight(.bold)
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button {
                            dismissKeyboard()
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                        }
                        .foregroundStyle(.orange)
                    }
                }
            }
            
            // Alert Configurations
            .alert("Update Failed", isPresented: $showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("The quiz name must be unique among all quizzes in this classroom.")
            }
            
            .alert("Are you sure?", isPresented: $deleteAlert) {
                Button("Yes", role: .destructive) {
                    deleteThisQuiz()
                }
                
                Button("No", role: .cancel) {}
            } message: {
                Text("This Quiz will be permanently deleted.")
            }
            
            // View Lifecycle
            .onAppear {
                print("👁️ [QuizDetailView] View appeared - initializing data fetch")

                getStats()
                getAllQuestions()
            }
            .refreshable {
                print("🔄 [QuizDetailView] Pull-to-refresh triggered")

                getAllQuestions()
                getStats()
                try? await Task.sleep(
                    nanoseconds: UInt64(
                        1_000_000_000
                    )
                )
            }
        }
    }

    // MARK: - UI Component Views

    /// Header section containing quiz title, metadata, and editing controls
    /// Provides different interfaces for creators (editable) vs students (read-only)
    /// Handles quiz name and deadline editing with validation feedback
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                if isCreator && isEditing {
                    
                    // Editable quiz name field for creators
                    // Disabled during save operations to prevent conflicts
                    TextField("Quiz Title", text: $quizName)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isSaving)
                    
                } else {
                    
                    // Read-only quiz name display
                    // Standard text presentation for viewing mode
                    Text(quizName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                }

                if isCreator {
                    
                    // Edit/Save button for quiz creators
                    // Toggles between edit mode and save operation
                    Button {
                        if isEditing {
                            
                            updateQuiz()
                            
                        } else {
                            
                            withAnimation {
                                isEditing = true
                            }
                            
                        }
                    } label: {
                        if isSaving {
                            
                            ProgressView()
                            
                        } else {
                            
                            Image(systemName: isEditing ? "checkmark.circle.fill" : "pencil.circle.fill")
                                .font(.title2)
                                .tint(isEditing ? .green : .accentColor)
                        }
                    }
                    .disabled(isSaving || (isEditing && !isUpdationValid))
                    
                    // Cancel edit button (only visible during editing)
                    // Reverts changes and exits editing mode
                    if isEditing {
                        
                        Button {
                            
                            withAnimation {
                                isEditing = false
                                quizName = quiz.quizName
                                deadline = quiz.deadline
                            }
                                
                        } label: {
                            Image(systemName: "x.circle")
                                .font(.title2)
                                .tint(.gray)
                        }
                        
                    }
                }
            }

            if isCreator && isEditing {
                
                // Deadline picker for quiz creators during editing
                // Validates that deadline is after creation date
                DatePicker("Deadline",
                           selection: $deadline,
                           in: quizCreatedAt...,
                           displayedComponents:
                            [.date,
                             .hourAndMinute
                            ]
                )
                .datePickerStyle(.compact)
                
            } else {
                
                // Read-only deadline and creation date display
                // Shows timing information with appropriate styling
                VStack(spacing: 4) {
                    Text(
                        "Deadline: \(deadline.formatted(date: .abbreviated, time: .shortened))"
                    )
                    .foregroundStyle( hasDeadlinePassed ? .red : .secondary)
                    .fontWeight(hasDeadlinePassed ? .bold : .medium)
                    
                    Text(
                        "Created at: \(quizCreatedAt.formatted(date: .abbreviated, time: .shortened))"
                    )
                    .foregroundStyle(.secondary)
                    .fontWeight(.medium)
                }
                .font(.footnote)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.gray.opacity(0.4), radius: 4, x: 0, y: 2)
    }

    /// Retry section displayed when statistics fetching fails
    /// Provides user-friendly error message and retry functionality
    private var retrySection: some View {
        VStack(spacing: 20) {
            Text("An error occurred while fetching your attempts.")
            Button {
                getStats()
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
            }
            .buttonStyle(.borderedProminent)
        }
    }

    /// List of user's quiz attempts with chronological display
    /// Shows attempt dates, scores, and late submission indicators
    private var attemptList: some View {
        VStack(alignment: .leading, spacing: 12) {
            
            Text("Your Attempts")
                .font(.title3)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ForEach(sortedAttempts, id: \.self) { attempt in
                attemptCell(attempt: attempt)
            }
        }
    }

    /// Individual attempt cell showing date, score, and late status
    /// Provides visual feedback for late submissions with color coding
    ///
    /// - Parameter attempt: The quiz attempt to display
    /// - Returns: A styled view showing attempt information
    private func attemptCell(attempt: Attempt) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(attempt.attemptDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if attempt.attemptDate > quiz.deadline {
                    Label("Late", systemImage: "clock.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            Spacer()
            Text("\(attempt.score)/\(attempt.totalScore)")
                .fontWeight(.bold)
                .foregroundStyle(
                    attempt.attemptDate > quiz.deadline ?
                        .red :
                        .green
                )
        }
        .padding()
        .background(Color.orange.opacity(0.35))
        .cornerRadius(12)
    }
    
    /// Primary action button section with role-based functionality
    /// Handles quiz taking, statistics viewing, and quiz deletion
    private var primaryActionButton: some View {
        VStack(spacing: 15) {
            
            // Main quiz interaction button
            // Text and functionality vary based on question loading state
            Button {
                
                if didFailDownloadingQuestions {
                    
                    getAllQuestions()
                    
                } else {
                    
                    startQuiz = true
                    
                }
            } label: {
                
                if isDownloadingQuestions {
                    
                    // Loading state during question fetch
                    HStack {
                        Text("Loading...")
                            .font(.footnote)
                        
                        ProgressView()
                    }
                    .foregroundStyle(.primary)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    
                } else if didFailDownloadingQuestions {
                    
                    // Error state with retry functionality
                    Label(
                        "Failed to load quiz questions. Tap to retry.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    
                } else if isQuestionArrayEmpty {
                    
                    // Empty questions error state
                    Label(
                        "No Questions available. Please contact the quiz creator.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    
                } else {
                    
                    // Normal state with role-appropriate button text
                    let label = isCreator
                    ? "View Quiz"
                    : (attempts.isEmpty ? "Start Quiz" : "Retake Quiz")
                    
                    Text(label)
                        .frame(maxWidth: .infinity)
                        .fontWeight(.bold)
                        .padding(8)
                    
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(
                isDownloadingQuestions
                ||
                isQuestionArrayEmpty
            )
            
            // Creator-only buttons for quiz management
            if isCreator {
                
                // Statistics viewing button for creators
                NavigationLink {
                    QuizStatsView(
                        classroomId: classroomId,
                        quizId: quizId,
                        deadline: deadline
                    )
                } label: {
                    Text("See Results")
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                }
                .buttonStyle(.borderedProminent)
                .tint(.secondary)
                
                // Quiz deletion button with confirmation
                Button {
                    
                    deleteAlert = true
                    
                } label: {
                    
                    if isDeleting {
                        
                        // Deletion in progress state
                        HStack {
                            ProgressView()
                            Text("Deleting...")
                        }
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        
                    } else if errorInDeleting {
                        
                        // Deletion error state
                        Label(
                            "Error occured while deleting. Try again?",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        
                    } else {
                        
                        // Normal deletion button state
                        Text("Delete Quiz")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(8)
                        
                    }
                }
                .disabled(isDeleting)
                .buttonStyle(.borderedProminent)
                .tint((isDeleting || errorInDeleting) ? .secondary : .red)
            }
        }
    }

    /// Quiz rules and information section
    /// Provides important information about quiz mechanics and scoring
    private var quizRulesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Quiz Rules")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 10) {
                Label("Each correct answer gives +1 point. No negative marking.", systemImage: "checkmark.seal")
                Label("Tapping an answer locks it in, so choose carefully.", systemImage: "hand.tap.fill")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
    
    // MARK: - Data Management Methods

    /// Updates quiz name and deadline through DataManager
    /// Validates changes and handles success/failure responses
    /// Updates local quiz object on successful database update
    private func updateQuiz() {
        withAnimation {
            isSaving = true
            showError = false
        }
        
        DataManager.shared.updateQuizNameDeadline(
            classroomId: classroomId,
            quizId: quizId,
            quizName: cleanedQuizName,
            deadline: deadline,
            createdAt: quizCreatedAt,
            completionHandler: { updatedName in
                print("📡 [QuizDetailView] Received update response from DataManager")
                
                guard let updatedName = updatedName else {
                    print("❌ [QuizDetailView] Quiz update failed - name conflict or validation error")

                    DispatchQueue.main.async {
                        withAnimation {
                            quizName = quiz.quizName
                            deadline = quiz.deadline
                            
                            isSaving = false
                            showError = true
                            isEditing = false
                        }
                    }
                    return
                }
                
                print("✅ [QuizDetailView] Quiz update successful - new name: '\(updatedName)'")
                DispatchQueue.main.async {
                    withAnimation {
                        quiz.deadline = deadline
                        quiz.quizName = updatedName
                        
                        quizName = updatedName
                        
                        isSaving = false
                        isEditing = false
                    }
                }
                
            }
        )
    }

    /// Fetches user's quiz statistics and attempt history
    /// Updates UI state based on success/failure and data availability
    /// Called on view appearance and after quiz completion
    private func getStats() {
        withAnimation {
            isLoading = true
            errorInFetchingStat = false
        }

        DataManager.shared.getQuizStatsForUser(
            classroomId: classroomId,
            quizId: quizId,
            userId: userId
        ) { result in
            print("📡 [QuizDetailView] Received statistics response from DataManager")

            DispatchQueue.main.async {
                withAnimation {
                    switch result {
                        
                    case nil:
                        print("❌ [QuizDetailView] Statistics fetch failed - network or database error")
                        self.errorInFetchingStat = true
                        self.isLoading = false
                        
                    case .some(nil):
                        print("📊 [QuizDetailView] No statistics found - user has not taken quiz")

                        self.attempts = []
                        self.isLoading = false
                        
                    case .some(let stat?):
                        print("✅ [QuizDetailView] Statistics loaded - \(stat.attempts.count) attempts found")

                        self.attempts = stat.attempts
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
    /// Fetches all questions for this quiz from Firebase
    /// Validates question availability before enabling quiz taking
    /// Handles loading states and error conditions appropriately
    private func getAllQuestions() {
        
        withAnimation {
            isDownloadingQuestions = true
            didFailDownloadingQuestions = false
            isQuestionArrayEmpty = false
        }
        
        DataManager.shared.getAllQuestionsFromQuiz(
            classroomId: classroomId,
            quizId: quizId,
            completionHandler: { questionData in
                print("📡 [QuizDetailView] Received questions response from DataManager")
                
                DispatchQueue.main.async {
                    
                    if let questionData = questionData {
                        
                        if questionData.isEmpty {
                            print("❌ [QuizDetailView] Quiz has no questions - cannot be taken")

                            withAnimation {
                                isDownloadingQuestions = false
                                isQuestionArrayEmpty = true
                            }
                            
                        } else {
                            print("✅ [QuizDetailView] Questions loaded successfully - \(questionData.count) questions")

                            withAnimation {
                                isDownloadingQuestions = false
                                questions = questionData
                            }
                        }
                        
                    } else {
                        print("❌ [QuizDetailView] Questions fetch failed - network or database error")

                        withAnimation {
                            isDownloadingQuestions = false
                            didFailDownloadingQuestions = true
                        }
                        
                    }
                }
                
            }
        )
    }
    
    /// Deletes the quiz and all associated data through DataManager
    /// Handles the destructive operation with appropriate user feedback
    /// Dismisses view on successful deletion
    private func deleteThisQuiz() {
        withAnimation {
            isDeleting = true
            errorInDeleting = false
        }
        
        DataManager.shared.deleteQuiz(
            classroomId: classroomId,
            quizId: quizId,
            completionHandler: { success in
                print("📡 [QuizDetailView] Received deletion response from DataManager: \(success)")
                
                DispatchQueue.main.async {
                    
                    if success {
                        print("✅ [QuizDetailView] Quiz deletion successful - dismissing view")

                        withAnimation {
                            isDeleting = false
                            dismiss()
                        }
                        
                    } else {
                        print("❌ [QuizDetailView] Quiz deletion failed - showing error state")

                        withAnimation {
                            isDeleting = false
                            errorInDeleting = true
                        }
                    }
                }
                
            }
        )
    }
    
    /// Programmatically dismisses the on-screen keyboard
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(
                UIResponder.resignFirstResponder
            ),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Preview

#Preview {
    QuizDetailView(
        classroomId: "gQatY3SaHOLK8vd9EUtl",
        userId: "3rNFDKJebENEfHqVFg475bJXb9j1",
        quizId: "1f3OThYT1HzBjy1USPLQ",
        quiz: Quiz(
            id: "1f3OThYT1HzBjy1USPLQ",
            createdAt: Date(),
            deadline: Date()
                .addingTimeInterval(+10000),
            quizName: "Module 2"
        ),
        quizCreatedAt: Date(),
        isCreator: true
    )
}
