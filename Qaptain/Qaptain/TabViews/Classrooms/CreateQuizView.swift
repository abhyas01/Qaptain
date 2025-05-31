//
//  CreateQuizView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/26/25.
//

import SwiftUI
import FirebaseFirestore

/// Full-screen modal view for creating comprehensive quizzes within classrooms
struct CreateQuizView: View {
    
    // MARK: - Properties

    /// The ID of the classroom where this quiz will be created
    let classroomId: String
    
    /// The ID of the user creating the quiz
    let userId: String
    
    /// Optional callback executed after successful quiz creation
    var onQuizCreated: (() -> Void)? = nil

    // MARK: - Environment Dependencies

    /// Environment value to programmatically dismiss this modal view
    @Environment(\.dismiss) private var dismiss

    // MARK: - State Properties

    /// Raw quiz name input by the user
    @State private var quizName = ""
    
    /// Selected deadline for quiz completion
    @State private var deadline = Date().addingTimeInterval(24*60*60)
    
    /// Array of questions being created for this quiz
    @State private var questions = [LocalQuestion()]
    
    /// Flag indicating whether the quiz creation request is in progress
    @State private var isCreating = false
    
    /// Flag to display error messages when creation fails
    @State private var showError = false

    // MARK: - Computed Properties

    /// Cleaned and normalized version of the quiz name
    private var cleanedQuizName: String {
        quizName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    /// Validates whether the quiz name meets length requirements
    private var isQuizNameValid: Bool {
        let nameCount = cleanedQuizName.count
        return (nameCount >= 4 && nameCount <= 60)
    }
    
    /// Validates that all questions in the quiz have proper content and answers
    private var areAllQuestionsValid: Bool {
        questions.allSatisfy { $0.isValid }
    }
    
    /// Validates all form requirements and determines if submission is allowed
    private var canSubmit: Bool {
        isQuizNameValid && deadline > Date().addingTimeInterval(30*60) && areAllQuestionsValid && !isCreating
    }

    // MARK: - View Body

    var body: some View {
        NavigationStack {
            Form {
                
                // Quiz Title Section
                Section("Quiz Title") {
                    TextField("e.g. Mid‑Term", text: $quizName)
                }
                
                // Deadline Selection Section
                Section("Deadline") {
                    DatePicker(
                        "Deadline",
                        selection: $deadline,
                        in: Date().addingTimeInterval(60*60)...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

                // Questions Management Section
                Section("Questions (\(questions.count))") {
                    ForEach(questions.indices, id: \.self) { idx in
                        
                        QuestionEditor(
                            question: $questions[idx],
                            canDelete: questions.count > 1,
                            onDelete: { questions.remove(at: idx) }
                        )
                        .padding(.vertical, 10)
                        
                    }
                    
                    Button {
                        print("➕ [CreateQuizView] Adding new question - current count: \(questions.count)")
                        questions.append(LocalQuestion())
                    } label: {
                        Label("Add Question", systemImage: "plus.circle")
                    }
                }
                
                // Error Display Section
                if showError {
                    Text("The quiz name must be unique among all quizzes in this classroom.")
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
                
                // Submit Button Section
                Section {
                    Button {
                        print("🚀 [CreateQuizView] User tapped create quiz button")

                        createQuiz()
                        
                    } label: {
                        
                        HStack {
                            if isCreating {
                                
                                ProgressView()
                                Text("Creating…")
                                
                            } else if showError {
                                
                                Label(
                                    "Failed to submit. Tap to retry.",
                                    systemImage: "exclamationmark.triangle.fill"
                                )
                            
                            } else {
                                
                                Image(systemName: "checkmark.circle.fill")
                                Text("Create Quiz")
                                
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                    }
                    .disabled(!canSubmit)
                }
                .listRowBackground(
                    canSubmit ? Color.orange.opacity(0.2)
                    : showError ? Color.red.opacity(0.3)
                    : Color.clear
                )
            }
            
            // Navigation Configuration
            .navigationTitle("New Quiz")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
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
        }
    }

    // MARK: - Question Editor Component

    /// Embedded view for editing individual quiz questions
    private struct QuestionEditor: View {
        
        /// Binding to the question being edited
        @Binding var question: LocalQuestion
        
        /// Whether this question can be deleted (false if it's the only question)
        var canDelete: Bool
        
        /// Callback executed when the delete button is tapped
        var onDelete: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 14) {
                
                // Question Header with Delete Button
                VStack(alignment: .leading) {
                    
                    if canDelete {
                        HStack {
                            Spacer()
                            Button(role: .destructive, action: onDelete) {
                                Image(systemName: "xmark.circle.fill")
                                    .imageScale(.large)
                                    .foregroundStyle(.red)
                            }
                            .buttonStyle(.plain)
                            .padding(.leading, 4)
                        }
                    }
                    
                    TextField("Question", text: $question.prompt)
                        .textFieldStyle(.roundedBorder)
                }

                // Answer Options Section
                ForEach(question.options.indices, id: \.self) { idx in
                    HStack {
                        
                        let trimmedOption = question.options[idx].trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Answer selection button
                        Button {
                            guard !trimmedOption.isEmpty else { return }
                            
                            if question.answer == trimmedOption {
                                
                                question.answer = ""
                                
                            } else {
                                
                                question.answer = trimmedOption
                            }
                            
                        } label: {
                            
                            Image(
                                systemName:
                                        question.answer == trimmedOption
                                        
                                    &&
                                        !trimmedOption.isEmpty
                                    ? 
                                        "largecircle.fill.circle"
                                    : 
                                        "circle"
                            )
                            .foregroundColor(.accentColor)
                        }
                        .buttonStyle(.plain)
                        .disabled(trimmedOption.isEmpty)

                        // Option text field
                        TextField("Option \(idx + 1)", text: $question.options[idx])
                            .textFieldStyle(.roundedBorder)

                        // Remove option button (if more than 1 option exists)
                        if question.options.count > 1 {
                            
                            Button(role: .destructive) {
                                if question.answer == trimmedOption {
                                    question.answer = ""
                                }
                                
                                question.options.remove(at: idx)
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Add option button (maximum 5 options allowed)
                Button {
                    question.options.append("")
                } label: {
                    Label("Add Option", systemImage: "plus")
                }
                .disabled(question.options.count >= 5)
                .font(.footnote)
            }
            .padding(.vertical, 6)
        }
    }

    // MARK: - Quiz Creation Logic

    /// Initiates the quiz creation process through DataManager
    private func createQuiz() {
        withAnimation {
            isCreating = true
            showError = false
        }

        print("⏳ [CreateQuizView] UI state updated - loading: true, error cleared")
        
        DataManager.shared.createQuiz(
            classroomId: classroomId,
            quizName: cleanedQuizName,
            deadline: deadline,
            questions: questions,
            completionHandler: { result in
                DispatchQueue.main.async {
                    switch result {
                        
                    case true:
                        
                        // Quiz created successfully
                        print("🎉 [CreateQuizView] Quiz creation successful!")

                        withAnimation {
                            isCreating = false
                            onQuizCreated?()
                            dismiss()
                        }
                        
                    case false:
                        
                        // Validation failed (duplicate name or other validation error)
                        print("❌ [CreateQuizView] Quiz creation failed - validation error")

                        withAnimation {
                            isCreating = false
                            showError = true
                        }
                        
                    default:
                        
                        // System error or unexpected response
                        withAnimation {
                            isCreating = false
                            showError = true
                        }
                    }
                }
            }
        )
    }
    
    // MARK: - Helper Methods

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
    CreateQuizView(classroomId: "demoClassId", userId: "demoUserId")
}
