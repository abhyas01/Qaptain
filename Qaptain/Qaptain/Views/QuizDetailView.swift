//
//  QuizDetailView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/28/25.
//

import SwiftUI

struct QuizDetailView: View {
    
    let classroomId: String
    let userId: String
    let quizId: String
    @State var quiz: Quiz
    let quizCreatedAt: Date
    let isCreator: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var quizName: String
    @State private var deadline: Date
    
    @State private var isEditing = false
    @State private var isSaving = false
    @State private var showError = false

    @State private var attempts: [Attempt] = []
    @State private var isLoading = true
    @State private var errorInFetchingStat = false

    @State private var questions: [Question] = []
    @State private var isDownloadingQuestions: Bool = false
    @State private var didFailDownloadingQuestions: Bool = false
    @State private var isQuestionArrayEmpty: Bool = false
    
    @State private var startQuiz: Bool = false
    
    @State private var isDeleting: Bool = false
    @State private var errorInDeleting: Bool = false
    @State private var deleteAlert: Bool = false
    
    private var sortedAttempts: [Attempt] {
        attempts.sorted(by: { $0.attemptDate > $1.attemptDate })
    }
    
    private var hasDeadlinePassed: Bool {
        return Date() > deadline
    }
    
    private var cleanedQuizName: String {
        let trimmedQuizName = quizName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let components = trimmedQuizName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return components.joined(separator: " ")
    }
    
    private var isUpdationValid: Bool {
        
        let nameCount = cleanedQuizName.count
        return (
            (nameCount >= 4 && nameCount <= 60)
            &&
            (deadline > quizCreatedAt)
        )
    }
    
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

    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                ScrollView {
                    VStack(spacing: 70) {
                        headerSection
                        
                        if isLoading {
                            
                            ProgressView("Fetching Attempts...")
                                .progressViewStyle(
                                    CircularProgressViewStyle(
                                        tint: .orange
                                    )
                                )
                            
                        } else if errorInFetchingStat {
                            
                            retrySection
                            
                        } else {
                            
                            if !attempts.isEmpty {
                                
                                attemptList
                                
                            }
                        }
                        
                        primaryActionButton
                        
                        quizRulesSection
                    }
                    .padding()
                    .frame(minHeight: geometry.size.height)
                }
            }
            .fullScreenCover(isPresented: $startQuiz) {
                QuestionsView(
                    classroomId: classroomId,
                    userId: userId,
                    quizId: quizId,
                    quizName: quiz.quizName,
                    questions: questions
                ) {
                    getStats()
                }
            }
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
            
            .onAppear {
                getStats()
                getAllQuestions()
            }
            .refreshable {
                getStats()
                try? await Task.sleep(
                    nanoseconds: UInt64(
                        1_000_000_000
                    )
                )
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                if isCreator && isEditing {
                    
                    TextField("Quiz Title", text: $quizName)
                        .textFieldStyle(.roundedBorder)
                        .disabled(isSaving)
                    
                } else {
                    
                    Text(quizName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                }

                if isCreator {
                    
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
    
    private var primaryActionButton: some View {
        VStack(spacing: 15) {
            
            Button {
                
                if didFailDownloadingQuestions {
                    
                    getAllQuestions()
                    
                } else {
                    
                    startQuiz = true
                    
                }
            } label: {
                
                if isDownloadingQuestions {
                    
                    HStack {
                        Text("Loading...")
                            .font(.footnote)
                        
                        ProgressView()
                    }
                    .foregroundStyle(.primary)
                    .padding(8)
                    .frame(maxWidth: .infinity)
                    
                } else if didFailDownloadingQuestions {
                    
                    Label(
                        "Failed to load quiz questions. Tap to retry.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .font(.subheadline)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    
                } else if isQuestionArrayEmpty {
                    
                    Label(
                        "No Questions available. Please contact the quiz creator.",
                        systemImage: "exclamationmark.triangle.fill"
                    )
                    .foregroundStyle(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    
                } else {
                    
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
            
            if isCreator {
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
                
                Button {
                    
                    deleteAlert = true
                    
                } label: {
                    
                    if isDeleting {
                        
                        HStack {
                            ProgressView()
                            Text("Deleting...")
                        }
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        
                    } else if errorInDeleting {
                        
                        Label(
                            "Error occured while deleting. Try again?",
                            systemImage: "exclamationmark.triangle.fill"
                        )
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(8)
                        
                    } else {
                        
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
                
                guard let updatedName = updatedName else {
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
            DispatchQueue.main.async {
                withAnimation {
                    switch result {
                        
                    case nil:
                        self.errorInFetchingStat = true
                        self.isLoading = false
                        
                    case .some(nil):
                        self.attempts = []
                        self.isLoading = false
                        
                    case .some(let stat?):
                        self.attempts = stat.attempts
                        self.isLoading = false
                    }
                }
            }
        }
    }
    
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
                
                DispatchQueue.main.async {
                    
                    if let questionData = questionData {
                        
                        if questionData.isEmpty {
                            
                            withAnimation {
                                isDownloadingQuestions = false
                                isQuestionArrayEmpty = true
                            }
                            
                        } else {
                            
                            withAnimation {
                                isDownloadingQuestions = false
                                questions = questionData
                            }
                        }
                        
                    } else {
                     
                        withAnimation {
                            isDownloadingQuestions = false
                            didFailDownloadingQuestions = true
                        }
                        
                    }
                }
                
            }
        )
    }
    
    private func deleteThisQuiz() {
        withAnimation {
            isDeleting = true
            errorInDeleting = false
        }
        
        DataManager.shared.deleteQuiz(
            classroomId: classroomId,
            quizId: quizId,
            completionHandler: { success in
                
                DispatchQueue.main.async {
                    
                    if success {
                     
                        withAnimation {
                            isDeleting = false
                            dismiss()
                        }
                        
                    } else {
                        
                        withAnimation {
                            isDeleting = false
                            errorInDeleting = true
                        }
                    }
                }
                
            }
        )
    }
    
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
