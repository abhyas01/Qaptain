//
//  QuizStatsView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/30/25.
//

import SwiftUI

/// This view provides teachers with complete oversight of how all students performed on a specific quiz
struct QuizStatsView: View {
    
    // MARK: - Immutable Properties

    /// Unique identifier of the classroom containing this quiz
    let classroomId: String
    
    /// Unique identifier of the specific quiz being analyzed
    let quizId: String
    
    /// Quiz deadline for determining late submission status
    let deadline: Date
    
    // MARK: - State Properties

    /// Array containing all student quiz statistics fetched from Firebase
    @State private var stats: [QuizStat] = []
    
    /// Current search query string for filtering student statistics
    @State private var query: String = ""
    
    /// Sort order flag determining chronological organization of statistics
    @State private var isDescending: Bool = true
    
    /// Loading state indicator for network operations and data fetching
    @State private var isLoading: Bool = false
    
    /// Error state indicator for failed network operations
    @State private var isError: Bool = false

    // MARK: - Computed Properties

    /// Filtered array of quiz statistics based on current search query
    private var filteredStats: [QuizStat] {
        if query.isEmpty {
            return stats
        } else {
            return stats.filter { stat in
                stat.name.localizedCaseInsensitiveContains(query) ||
                stat.email.localizedCaseInsensitiveContains(query)
            }
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack {

                List {
                    
                    // Main content area displaying statistics when no errors are present
                    // Handles empty states, loading states, and populated data lists
                    if !isError {
                        
                        // Displays appropriate empty state messages based on search context
                        // Differentiates between no data available vs no search results
                        if filteredStats.isEmpty {
                            
                            if !isLoading {
                                
                                if query.isEmpty {
                                    
                                    // No quiz statistics exist yet - first-time teacher view
                                    Text("No stats available yet.")
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                } else {
                                    
                                    // Search query yielded no results - inform user
                                    Text("No student matches your search query")
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                        } else {
                            
                            // Main data display area showing filtered quiz statistics
                            // Each row links to detailed individual student attempt history
                            ForEach(filteredStats) { stat in
                                NavigationLink {
                                    
                                    // Navigate to detailed individual student view
                                    StudentAttemptsDetailView(stat: stat, deadline: deadline)
                                } label: {
                                    
                                    // Display individual student statistics card
                                    QuizStatCell(stat: stat, deadline: deadline)
                                }
                                .listRowSeparator(.hidden)
                            }
                        }
                        
                        // Progress indicator shown during network operations
                        // Prevents user confusion during data fetching delays
                        if isLoading {
                            
                            HStack {
                                Text("Loading...")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                ProgressView()
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                    } else {
                        
                        // Error handling interface with retry functionality
                        // Displayed when network requests fail or database errors occur
                        VStack {
                            Text("An error occured while fetching stats.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            
                            Button {
                                
                                // Retry statistics fetching operation
                                fetchStats()
                            } label: {
                                Label("Retry?", systemImage: "arrow.counterclockwise")
                                    .font(.footnote)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 10)
                            }
                            .buttonStyle(.borderedProminent)
                            .padding(.vertical, 20)
                        }
                        .frame(maxWidth: .infinity)
                        
                    }
                }
                .listRowSpacing(25)
                
                // Enables teachers to manually refresh statistics data
                // Essential for getting updated student attempts and scores
                .refreshable {
                    fetchStats()
                    
                    // Add brief delay for better user experience feedback
                    try? await Task.sleep(nanoseconds: 800_000_000)
                }
                
                // Real-time search capability across student names and emails
                // Updates filteredStats computed property automatically
                .searchable(text: $query)
            }
            
            //Navigation Configuration
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "person.3.sequence")
                        Text("Quiz Results")
                    }
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.orange)
                    .fontWeight(.bold)
                }
                
                // Sort options menu displayed only when data is available
                // Prevents UI clutter when no statistics exist to sort
                if !filteredStats.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        sortButton
                    }
                }
                
                // Toolbar button for dismissing keyboard during search operations
                // Improves user experience when typing search queries
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        Button {
                            dismissKeyboard()
                        } label: {
                            Image(systemName: "keyboard.chevron.compact.down")
                                .tint(.orange)
                        }
                    }
                }
            }
            
            // View Lifecycle
            .onAppear(perform: fetchStats)
            .tint(.orange)
            .accentColor(.orange)
        }
    }

    // MARK: - Sort Menu Component

    /// Creates dropdown menu for sorting quiz statistics by attempt chronology
    /// Provides teachers with flexible data organization options for analysis
    /// Shows current selection with checkmark for clear user feedback
    private var sortButton: some View {
        Menu {
            Section("Sort By Date") {
                Button {
                    
                    // Sort by newest attempts first
                    if !isDescending { isDescending = true; fetchStats() }
                } label: {
                    HStack {
                        Text("Newest First")
                        if isDescending {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
                Button {
                    
                    // Sort by oldest attempts first
                    if isDescending { isDescending = false; fetchStats() }
                } label: {
                    HStack {
                        Text("Oldest First")
                        if !isDescending {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            Label("Sort", systemImage: "arrow.up.arrow.down")
        }
    }

    // MARK: - Data Management Methods

    /// Fetches all quiz statistics from Firebase Firestore for teacher review
    private func fetchStats() {
        
        // Update UI to show loading state and clear any previous errors
        withAnimation {
            isLoading = true
            isError = false
        }
        
        // Call DataManager to retrieve quiz statistics from Firebase
        DataManager.shared.getAllQuizStatsForAdmin(
            classroomId: classroomId,
            quizId: quizId,
            isDescending: isDescending
        ) { result in
            DispatchQueue.main.async {
                print("📡 [QuizStatsView] Received statistics response from DataManager")

                withAnimation {
                    isLoading = false
                    
                    if let result = result {
                        
                        // Statistics fetch successful - update data array
                        print("✅ [QuizStatsView] Statistics fetch successful - loaded \(result.count) student records")
                        stats = result
                        
                    } else {
                        
                        // Statistics fetch failed - show error state
                        print("❌ [QuizStatsView] Statistics fetch failed - displaying error interface")
                        isError = true
                    }
                }
            }
        }
    }

    // MARK: - Utility Methods

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
    QuizStatsView(
        classroomId: "gQatY3SaHOLK8vd9EUtl",
        quizId: "1f3OThYT1HzBjy1USPLQ",
        deadline: Date().addingTimeInterval(-10000)
    )
}
