//
//  QuizStatsView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/30/25.
//

import SwiftUI

struct QuizStatsView: View {
    
    let classroomId: String
    let quizId: String
    let deadline: Date
    
    @State private var stats: [QuizStat] = []
    @State private var query: String = ""
    @State private var isDescending: Bool = true
    @State private var isLoading: Bool = false
    @State private var isError: Bool = false

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

    var body: some View {
        NavigationStack {
            VStack {

                List {
                    
                    if !isError {
                        
                        if filteredStats.isEmpty {
                            
                            if !isLoading {
                                
                                if query.isEmpty {
                                    
                                    Text("No stats available yet.")
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                } else {
                                    
                                    Text("No student matches your search query")
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                        } else {
                            
                            ForEach(filteredStats) { stat in
                                NavigationLink {
                                    StudentAttemptsDetailView(stat: stat, deadline: deadline)
                                } label: {
                                    QuizStatCell(stat: stat, deadline: deadline)
                                }
                                .listRowSeparator(.hidden)
                            }
                        }
                        
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
                        
                        VStack {
                            Text("An error occured while fetching stats.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Button {
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
                .refreshable {
                    fetchStats()
                    try? await Task.sleep(nanoseconds: 800_000_000)
                }
                .searchable(text: $query)
            }
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
                
                if !filteredStats.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        sortButton
                    }
                }
                
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
            .onAppear(perform: fetchStats)
            .tint(.orange)
            .accentColor(.orange)
        }
    }

    private var sortButton: some View {
        Menu {
            Section("Sort By Date") {
                Button {
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

    private func fetchStats() {
        withAnimation {
            isLoading = true
            isError = false
        }
        
        DataManager.shared.getAllQuizStatsForAdmin(
            classroomId: classroomId,
            quizId: quizId,
            isDescending: isDescending
        ) { result in
            DispatchQueue.main.async {
                withAnimation {
                    isLoading = false
                    
                    if let result = result {
                        
                        stats = result
                        
                    } else {
                        
                        isError = true
                    }
                }
            }
        }
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
    QuizStatsView(
        classroomId: "gQatY3SaHOLK8vd9EUtl",
        quizId: "1f3OThYT1HzBjy1USPLQ",
        deadline: Date().addingTimeInterval(-10000)
    )
}
