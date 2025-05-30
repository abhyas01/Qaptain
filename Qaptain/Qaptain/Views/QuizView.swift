//
//  QuizView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/27/25.
//

import SwiftUI

struct QuizView: View {

    let userId: String
    let classroomId: String
    let classroomName: String
    let createdByName: String
    let isCreator: Bool
    
    @State private var quizData: [Quiz] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil
    @State private var showAddQuizSheet = false
    
    @State private var isDescending = true
    @State private var sortByDeadline = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            if isLoading {
                
                ProgressView("Loading quizzes...")
                    .progressViewStyle(
                        CircularProgressViewStyle(
                            tint: .orange
                        )
                    )
                
            } else if let errorMessage = errorMessage {
                
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                    
                    Button {
                        getQuizData()
                    } label: {
                        Label("Retry?",
                              systemImage: "arrow.counterclockwise"
                        )
                    }
                    .disabled(isLoading)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 20)
                }
                
            } else if quizData.isEmpty && !isCreator {
                
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("No quizzes available.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        getQuizData()
                    } label: {
                        Label("Refresh?",
                              systemImage: "arrow.counterclockwise"
                        )
                    }
                    .disabled(isLoading)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, 20)
                }
                
            } else {
                
                GeometryReader { geometry in
                    ScrollView {
                        Group {
                            quizGridView
                        }
                        .frame(minHeight: geometry.size.height)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack {
                    Image(systemName: "book.pages")
                    Text("Quizzes")
                }
                .font(.headline)
                .fontDesign(.rounded)
                .foregroundStyle(.orange)
                .fontWeight(.bold)
            }
            
            if !quizData.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    sortButton
                }
            }
        }
        
        .fullScreenCover(isPresented: $showAddQuizSheet) {
            CreateQuizView(
                classroomId: classroomId,
                userId: userId
            ) {
                getQuizData()
            }
        }
        
        .onAppear {
            getQuizData()
        }
        
        .refreshable {
            getQuizData()
            try? await Task.sleep(
                nanoseconds: UInt64(
                    1_000_000_000
                )
            )
        }
    }

    private var quizGridView: some View {
        LazyVGrid(
            columns: [
                GridItem(
                    .adaptive(
                        minimum:
                            quizData.isEmpty ?
                            .infinity :
                            160
                    ),
                    spacing: 16
                )
            ],
            spacing: 20
        ) {
            if isCreator {
                addQuizCell
            }
            
            ForEach(quizData) { quiz in
                if let quizCreatedAt = quiz.createdAt,
                   let quizId = quiz.id {
                    quizCell(
                        quizId: quizId,
                        quizCreatedAt: quizCreatedAt,
                        quiz: quiz
                    )
                }
            }
        }
        .padding()
    }
    
    private var addQuizCell: some View {
        Button(action: {
            showAddQuizSheet = true
        }) {
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 25))
                    .foregroundColor(.white)
                
                Text("Add Quiz")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, minHeight: 255, alignment: .center)
            .background(Color.purple.opacity(0.65))
            .cornerRadius(12)
            .shadow(color: .gray, radius: 5, x: 0, y: 2)
        }
    }
    
    private func quizCell(
        quizId: String,
        quizCreatedAt: Date,
        quiz: Quiz
    ) -> some View {
        NavigationLink {
            QuizDetailView(
                classroomId: classroomId,
                userId: userId,
                quizId: quizId,
                quiz: quiz,
                quizCreatedAt: quizCreatedAt,
                isCreator: isCreator
            )
        } label: {
            VStack(alignment: .leading, spacing: 15) {
                Text(quiz.quizName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(4)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                
                VStack(alignment: .leading) {
                    Text("Due")
                        .fontWeight(.heavy)
                        .font(.footnote)
                    
                    VStack(alignment: .leading) {
                        Text(
                            quiz.deadline.formatted(
                                date: .abbreviated,
                                time: .omitted
                            )
                        )
                        Text(
                            quiz.deadline.formatted(
                                date: .omitted,
                                time: .shortened
                            )
                        )
                    }
                    .font(.caption)
                }
                .foregroundStyle(.black)
                
                VStack(alignment: .leading) {
                    Text("Created")
                        .fontWeight(.heavy)
                        .font(.footnote)
                    
                    VStack(alignment: .leading) {
                        Text(
                            quiz.createdAt?.formatted(
                                date: .abbreviated,
                                time: .omitted
                            ) ??
                            "Unknown Date"
                        )
                        Text(
                            quiz.createdAt?.formatted(
                                date: .omitted,
                                time: .shortened
                            ) ??
                            "Unknown Time"
                        )
                    }
                    .font(.caption)
                }
                .foregroundStyle(.black)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.orange)
        .cornerRadius(12)
        .shadow(color: .gray, radius: 5, x: 0, y: 2)
    }
    
    private var sortButton: some View {
        Menu {
            
            Section("Sort By Creation Date") {
                Button {
                    sortByDeadline = false
                    isDescending = true
                    getQuizData()
                } label: {
                    HStack {
                        Text("Newest First")
                        if isDescending && !sortByDeadline {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button {
                    sortByDeadline = false
                    isDescending = false
                    getQuizData()
                } label: {
                    HStack {
                        Text("Oldest First")
                        if !isDescending && !sortByDeadline {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
            Section("Sort By Deadline"){
                Button {
                    sortByDeadline = true
                    isDescending = true
                    getQuizData()
                } label: {
                    HStack {
                        Text("Newest First")
                        if isDescending && sortByDeadline {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button {
                    sortByDeadline = true
                    isDescending = false
                    getQuizData()
                } label: {
                    HStack {
                        Text("Oldest First")
                        if !isDescending && sortByDeadline {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            
        } label: {
            Label(
                "Sort",
                systemImage: "arrow.up.arrow.down"
            )
        }
    }
    
    private func getQuizData() {
        withAnimation {
            errorMessage = nil
            isLoading = true
        }

        DataManager.shared.getAllQuizDocuments(
            classroomId: classroomId,
            isDescending: isDescending,
            sortByDeadline: sortByDeadline
        ) { quizDocs in
            DispatchQueue.main.async {
                withAnimation {
                    if let quizDocs = quizDocs {
                        quizData = quizDocs
                        isLoading = false
                    } else {
                        isLoading = false
                        errorMessage = "An error occurred while fetching quizzes."
                    }
                }
            }
        }
    }
}

#Preview {
    QuizView(
        userId: "3rNFDKJebENEfHqVFg475bJXb9j1",
        classroomId: "gQatY3SaHOLK8vd9EUtl",
        classroomName: "MPCS 51032",
        createdByName: "Abhyas Mall",
        isCreator: true
    )
}
