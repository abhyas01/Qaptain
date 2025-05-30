//
//  CreateQuizView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/26/25.
//

import SwiftUI
import FirebaseFirestore

struct CreateQuizView: View {
    let classroomId: String
    let userId: String
    var onQuizCreated: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss

    @State private var quizName = ""
    @State private var deadline = Date().addingTimeInterval(24*60*60)
    @State private var questions = [LocalQuestion()]
    @State private var isCreating = false
    @State private var showError = false

    private var cleanedQuizName: String {
        quizName
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    private var isQuizNameValid: Bool {
        let nameCount = cleanedQuizName.count
        return (nameCount >= 4 && nameCount <= 60)
    }
    
    private var areAllQuestionsValid: Bool {
        questions.allSatisfy { $0.isValid }
    }
    
    private var canSubmit: Bool {
        isQuizNameValid && deadline > Date().addingTimeInterval(60*60) && areAllQuestionsValid && !isCreating
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Quiz Title") {
                    TextField("e.g. Mid‑Term", text: $quizName)
                }
                
                Section("Deadline") {
                    DatePicker(
                        "Deadline",
                        selection: $deadline,
                        in: Date().addingTimeInterval(60*60)...,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }

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
                        questions.append(LocalQuestion())
                    } label: {
                        Label("Add Question", systemImage: "plus.circle")
                    }
                }
                
                if showError {
                    Text("The quiz name must be unique among all quizzes in this classroom.")
                        .frame(maxWidth: .infinity)
                        .multilineTextAlignment(.center)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .foregroundStyle(.red)
                        .font(.footnote)
                }
                
                Section {
                    Button {
                        
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

    private struct QuestionEditor: View {
        
        @Binding var question: LocalQuestion
        var canDelete: Bool
        var onDelete: () -> Void

        var body: some View {
            VStack(alignment: .leading, spacing: 14) {
                
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

                
                ForEach(question.options.indices, id: \.self) { idx in
                    HStack {
                        
                        let trimmedOption = question.options[idx].trimmingCharacters(in: .whitespacesAndNewlines)
                        
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

                        
                        TextField("Option \(idx + 1)", text: $question.options[idx])
                            .textFieldStyle(.roundedBorder)

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

    private func createQuiz() {
        withAnimation {
            isCreating = true
            showError = false
        }
        
        DataManager.shared.createQuiz(
            classroomId: classroomId,
            quizName: cleanedQuizName,
            deadline: deadline,
            questions: questions,
            completionHandler: { result in
                DispatchQueue.main.async {
                    switch result {
                        
                    case true:
                        withAnimation {
                            isCreating = false
                            onQuizCreated?()
                            dismiss()
                        }
                        
                    case false:
                        withAnimation {
                            isCreating = false
                            showError = true
                        }
                        
                    default:
                        withAnimation {
                            isCreating = false
                            showError = true
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

// MARK: - Preview
#Preview {
    CreateQuizView(classroomId: "demoClassId", userId: "demoUserId")
}
