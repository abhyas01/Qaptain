//
//  QuizView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/27/25.
//

import SwiftUI

/// Comprehensive quiz management hub that serves different functions based on user role
struct QuizView: View {

    // MARK: - Immutable Properties

    /// Unique identifier of the current user accessing quizzes
    let userId: String
    
    /// Unique identifier of the classroom containing these quizzes
    let classroomId: String
    
    /// Display name of the classroom for context and navigation
    let classroomName: String
    
    /// Full name of the user who created the classroom (teacher/instructor)
    let createdByName: String
    
    /// Boolean indicating if current user created this classroom
    let isCreator: Bool
    
    // MARK: - Quiz Data State

    /// Array containing all quiz objects fetched from Firebase Firestore
    @State private var quizData: [Quiz] = []
    
    /// Loading state indicator for quiz data fetching operations
    @State private var isLoading: Bool = true
    
    /// Error message string for failed network operations or data processing
    @State private var errorMessage: String? = nil
    
    /// Controls presentation of the full-screen quiz creation modal
    @State private var showAddQuizSheet = false
    
    // MARK: - Sorting and Organization State

    /// Sort order flag determining chronological organization of quiz display
    @State private var isDescending = true
    
    /// Sorting criteria flag determining primary sort field for quiz organization
    /// True = sort by deadline, False = sort by creation date for different viewing needs
    @State private var sortByDeadline = false

    // MARK: - Body

    var body: some View {
        ZStack {
            
            // Background color for consistent app theming
            Color(.systemGroupedBackground)
                .ignoresSafeArea()
            
            // Progress indicator shown during initial quiz data fetching
            // Prevents user confusion during network operations and database queries
            if isLoading {
                
                ProgressView("Loading quizzes...")
                    .progressViewStyle(
                        CircularProgressViewStyle(
                            tint: .orange
                        )
                    )
                
            // Error handling interface with retry functionality and user feedback
            // Displayed when network requests fail or Firebase operations encounter issues
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
                        
                        // Retry quiz data fetching operation
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
            
            // Student-specific empty state when no quizzes are available
            // Provides appropriate messaging and refresh options for students
            } else if quizData.isEmpty && !isCreator {
                
                VStack(spacing: 12) {
                    Image(systemName: "tray")
                        .font(.largeTitle)
                        .foregroundColor(.gray)
                    
                    Text("No quizzes available.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        
                        // Manual refresh for students to check for new quizzes
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
                
            // Main content area displaying quizzes in organized grid format
            // Responsive layout adapts to screen size and quiz count
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
        
        // Navigation Configuration
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
            
            // Sort options menu displayed only when quizzes exist to organize
            // Prevents UI clutter when no quiz data is available
            if !quizData.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    sortButton
                }
            }
        }
        
        // Full-screen quiz creation interface for classroom creators
        // Provides comprehensive quiz building tools with questions and deadlines
        .fullScreenCover(isPresented: $showAddQuizSheet) {
            CreateQuizView(
                classroomId: classroomId,
                userId: userId
            ) {
                
                // Refresh quiz data after successful quiz creation
                getQuizData()
            }
        }
        
        .onAppear {
            print("👁️ [QuizView] View appeared - initializing quiz data fetch")
            getQuizData()
        }
        
        // Manual refresh capability for updated quiz information
        // Essential for real-time updates of deadlines and new quiz availability
        .refreshable {
            getQuizData()
            
            // Brief delay for improved user experience feedback
            try? await Task.sleep(
                nanoseconds: UInt64(
                    1_000_000_000
                )
            )
        }
    }

    /// Creates responsive grid layout for quiz display with role-based content
    /// Adapts to screen size and includes creation card for teachers
    /// Organizes quizzes in visually appealing and accessible format
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
           
            // Special card allowing teachers to create new quizzes
            // Prominently displayed at beginning of grid for easy access
            if isCreator {
                addQuizCell
            }
            
            // Grid of existing quizzes with navigation to detailed views
            // Each card shows essential quiz information and deadlines
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
    
    /// Purple-themed card for teachers to create new quizzes
    /// Visually distinct from existing quizzes to encourage quiz creation
    /// Triggers full-screen modal presentation for comprehensive quiz building
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
    
    // MARK: - Individual Quiz Card Component
    
    /// Creates styled card for individual quiz display with navigation capability
    /// Shows quiz name, deadline, and creation date in organized format
    /// Orange-themed design maintains app consistency and visual hierarchy
    ///
    /// - Parameters:
    ///   - quizId: Unique identifier for quiz navigation and data operations
    ///   - quizCreatedAt: Creation timestamp for display and validation
    ///   - quiz: Complete quiz object with metadata and timing information
    /// - Returns: NavigationLink wrapped quiz card with comprehensive information display
    private func quizCell(
        quizId: String,
        quizCreatedAt: Date,
        quiz: Quiz
    ) -> some View {
        
        // Navigate to detailed quiz interface for management or taking
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
                
                // Primary quiz identification with limited line display
                // Bold white text for strong visual hierarchy and readability
                Text(quiz.quizName)
                    .font(.headline)
                    .fontWeight(.bold)
                    .lineLimit(4)
                    .foregroundStyle(.white)
                    .multilineTextAlignment(.leading)
                
                // Critical deadline information for student planning
                // Separated date and time for improved scanability
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
                
                // Quiz creation timestamp for teacher reference and organization
                // Helps teachers track quiz chronology and management history
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
    
    // MARK: - Sort Menu Component
    
    /// Creates dropdown menu for organizing quiz display by different criteria
    /// Provides teachers and students with flexible data organization options
    /// Shows current selection with checkmarks for clear user feedback
    private var sortButton: some View {
        Menu {
            
            // Sort options based on when quizzes were originally created
            // Useful for teachers tracking quiz development chronology
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
            
            // Sort options based on quiz submission deadlines
            // Critical for students prioritizing upcoming due dates
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
    
    // MARK: - Data Management Methods
    
    /// Fetches all quiz documents from Firebase Firestore for classroom display
    /// Updates UI state based on success/failure of network operations
    /// Handles loading states, error conditions, and data organization
    private func getQuizData() {
        
        // Update UI to show loading state and clear previous errors
        withAnimation {
            errorMessage = nil
            isLoading = true
        }

        // Call DataManager to retrieve quiz documents from Firebase
        DataManager.shared.getAllQuizDocuments(
            classroomId: classroomId,
            isDescending: isDescending,
            sortByDeadline: sortByDeadline
        ) { quizDocs in
            print("📡 [QuizView] Received quiz data response from DataManager")

            // Ensure UI updates happen on main thread for smooth animations
            DispatchQueue.main.async {
                withAnimation {
                    if let quizDocs = quizDocs {
                        
                        // Quiz fetch successful - update data array and UI
                        print("✅ [QuizView] Quiz data fetch successful - loaded \(quizDocs.count) quizzes")

                        quizData = quizDocs
                        isLoading = false
                    } else {
                        
                        // Quiz fetch failed - show error state with retry option
                        print("❌ [QuizView] Quiz data fetch failed - displaying error interface")

                        isLoading = false
                        errorMessage = "An error occurred while fetching quizzes."
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    QuizView(
        userId: "3rNFDKJebENEfHqVFg475bJXb9j1",
        classroomId: "gQatY3SaHOLK8vd9EUtl",
        classroomName: "MPCS 51032",
        createdByName: "Abhyas Mall",
        isCreator: true
    )
}
