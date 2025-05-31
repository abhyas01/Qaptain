//
//  ClassroomsView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/23/25.
//

import SwiftUI

/// Primary view for displaying and managing classrooms in the Qaptain app
/// This view handles two distinct user roles:
/// 1. Students: View enrolled classrooms and join new ones via password
/// 2. Teachers: View created classrooms and create new ones
/// Features include:
/// - Segmented picker to switch between enrolled/teaching classes
/// - Search functionality across classroom names, dates, and teacher names
/// - Pull-to-refresh data loading with pagination support
/// - Sort options by creation date (newest/oldest first)
/// - Modal sheets for creating/joining classrooms
/// - Empty state handling with appropriate messaging
/// - Error state handling with retry functionality
struct ClassroomsView: View {

    // MARK: - Dependencies

    /// Shared provider that manages classroom data fetching, pagination, and state
    /// Uses Firebase Firestore queries to get user's classrooms with proper filtering
    @StateObject private var provider: ClassroomProvider = ClassroomProvider.shared
    
    /// Current user's unique identifier from Firebase Auth
    /// Used to filter classrooms and determine user permissions
    let userId: String
    
    // MARK: - Class Selection Options

    /// Enum defining the two main classroom views available to users
    private enum ClassOptions: CaseIterable {
        case enrolledClasses
        case teachingClasses
        
        /// Human-readable string for UI display in segmented picker
        var getString: String {
            switch self {
            case .enrolledClasses:
                return "Enrolled Classes"
            case .teachingClasses:
                return "Teaching Classes"
            }
        }
    }
    
    // MARK: - State Properties

    /// Search query text for filtering classrooms by name, creator, or date
    @State private var query: String = ""
    
    /// Currently selected classroom view mode (enrolled vs teaching)
    @State private var classSelection: ClassOptions = .enrolledClasses
    
    /// Sort order flag - true for newest first, false for oldest first
    @State private var isDescending: Bool = true
    
    /// Controls presentation of the create classroom modal sheet
    @State private var showCreateNewClassroom: Bool = false
    
    /// Controls presentation of the join classroom modal sheet
    @State private var showEnrollNewClassroom: Bool = false
    
    /// Controls presentation of the app instructions/onboarding sheet
    @State private var showInstructions: Bool = false
    
    // MARK: - Computed Properties

    /// Determines if the view is currently in a loading/pagination state
    /// Used to prevent multiple simultaneous data requests and show loading indicators
    private var isPaginating: Bool {
        provider.isLoading || provider.classrooms.isEmpty
    }
    
    /// Maps the current class selection to a boolean for the data provider
    /// True = fetch classrooms where user is creator, False = fetch where user is member
    private var getClassesWithTeacherRole: Bool {
        classSelection == .teachingClasses ? true : false
    }
    
    /// Filters the classroom list based on the current search query
    /// Searches across classroom name, creation date (formatted as month/year), and creator name
    private var classrooms: [Classroom] {
        let classrooms = provider.classrooms
        
        // Empty query return all classrooms
        if query.isEmpty {
            return classrooms
            
        // Apply query filters
        } else {
            
            // Create date formatter for month/year search capability
            let monthDateFormatter = DateFormatter()
            monthDateFormatter.dateFormat = "MMMM yyyy"
            
            return classrooms.filter { classroom in
                
                // Search by classroom name
                let nameMatch = classroom.classroomName.localizedCaseInsensitiveContains(query)
                
                // Search by formatted creation date (e.g., "January 2025")
                var dateMatch = false
                if let createdAt = classroom.createdAt {
                    let monthYear = monthDateFormatter.string(from: createdAt)
                    dateMatch = monthYear.localizedCaseInsensitiveContains(query)
                }
                
                // Search by teacher/creator name
                let teacherMatch = classroom.createdByName.localizedCaseInsensitiveContains(query)
                
                return nameMatch || dateMatch || teacherMatch
            }
        }
    }

    // MARK: - View Body

    var body: some View {
        NavigationStack {
            VStack {
                
                // Segmented Picker Section
                Picker("Class Type",
                       selection: $classSelection
                ) {
                    ForEach(ClassOptions.allCases, id: \.self) { option in
                        Text(option.getString)
                    }
                }
                .pickerStyle(.segmented)
            
                // Main Content List
                List {
                    
                    // Handle non-error states (normal data display)
                    if !provider.isError {
                        
                        // Empty state handling
                        if classrooms.isEmpty {
                            
                            if !provider.isLoading {
                                
                                if query.isEmpty {
                                    
                                    // No classrooms exist for this user role
                                    Text(
                                        getClassesWithTeacherRole ?
                                        "You don't have any classes."
                                        :
                                            "You're not enrolled in any class."
                                    )
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                    
                                } else {
                                    
                                    // No search results found
                                    Text("Cannot find any class that matches your search query")
                                        .multilineTextAlignment(.center)
                                        .frame(maxWidth: .infinity)
                                        .font(.footnote)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            
                        } else {
                            
                            // Classroom List Items
                            ForEach(classrooms) { classroom in
                                if let id = classroom.id,
                                   let createdAt = classroom.createdAt {
                                    
                                    NavigationLink {
                                        
                                        // Navigate to detailed classroom view
                                        ClassroomDetailView(
                                            userId: userId,
                                            documentId: id,
                                            classroomName: classroom.classroomName,
                                            createdAt: createdAt,
                                            createdByName: classroom.createdByName,
                                            isCreator: getClassesWithTeacherRole,
                                            password: classroom.password
                                        )
                                    } label: {
                                        ClassroomsCell(
                                            classroomName: classroom.classroomName,
                                            createdByName: classroom.createdByName,
                                            createdAt: classroom.createdAt
                                        )
                                        .onAppear {
                                            loadMoreIfNeeded(current: classroom)
                                        }
                                    }
                                    .listRowSeparator(.hidden)
                                }
                            }
                        }
                        
                        // Loading indicator
                        if provider.isLoading {
                            HStack {
                                Text("Loading...")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                
                                ProgressView()
                            }
                            .frame(maxWidth: .infinity)
                        }
                        
                    // Error State Handling
                    } else {
                        
                        VStack {
                            Text("An error occured while fetching classrooms.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            
                            Button {
                                updateQuery()
                            } label: {
                                Label(
                                    "Retry?",
                                    systemImage: "arrow.counterclockwise"
                                )
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
            
                // MARK: - Modal Sheet Presentations

                .sheet(isPresented: $showCreateNewClassroom) {
                    CreateClassroomSheet(userId: userId) {
                        isDescending = true
                        updateQuery()
                    }
                }
            
                .sheet(isPresented: $showEnrollNewClassroom) {
                    EnrollClassroomSheet(userId: userId) {
                        isDescending = true
                        updateQuery()
                    }
                }
            
                .sheet(isPresented: $showInstructions) {
                    InstructionsView()
                }
                
                .listRowSpacing(25)
                .refreshable {
                    updateQuery()
                    try? await Task.sleep(
                        nanoseconds: UInt64(
                            1_000_000_000
                        )
                    )
                }
                .searchable(text: $query)
                
                // MARK: - Primary Action Button

                VStack {
                    Button {
                        
                        if getClassesWithTeacherRole {
                            
                            print("👨‍🏫 [ClassroomsView] Teacher tapped create new class button")
                            showCreateNewClassroom = true
                            
                        } else {
                            
                            print("🎓 [ClassroomsView] Student tapped enroll in new class button")
                            showEnrollNewClassroom = true
                        }
                        
                    } label: {
                        Label(
                            getClassesWithTeacherRole ?
                            "Create a new class" :
                                "Enroll in a new class",
                            systemImage: "plus"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .padding(.horizontal, 30)
                }
                .padding()
            }
            
            // MARK: - Toolbar Configuration

            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName:
                                getClassesWithTeacherRole ?
                              "book.circle" :
                                "graduationcap.circle"
                        )
                        
                        Text(
                            getClassesWithTeacherRole ?
                            "Teaching Classes" :
                                "Enrolled Classes"
                        )
                    }
                    .font(.title2)
                    .fontDesign(.rounded)
                    .foregroundStyle(.orange)
                    .fontWeight(.bold)
                }
                
                if !classrooms.isEmpty {
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
                            Image(
                                systemName: "keyboard.chevron.compact.down"
                            )
                            .tint(.orange)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showInstructions = true
                    } label: {
                        Label("Info", systemImage: "info.circle")
                    }
                }
            }
            .onAppear {
                print("👁️ [ClassroomsView] View appeared - initializing data and checking first launch")
                
                updateQuery()
                checkFirstLaunch()
            }
            .onChange(of: classSelection) { oldVal, newVal in
                if oldVal != newVal {
                    updateQuery()
                }
            }
            .tint(.orange)
            .accentColor(.orange)
        }
    }
    
    // MARK: - Sort Menu Component

    /// Creates a menu for sorting classrooms by creation date
    /// Provides options for newest-first or oldest-first ordering
    private var sortButton: some View {
        Menu {
            
            Section("Sort By Date"){
                Button {
                    print("📊 [ClassroomsView] User selected newest first sort")

                    isDescending = true
                    updateQuery()
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
                    print("📊 [ClassroomsView] User selected oldest first sort")

                    isDescending = false
                    updateQuery()
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
    
    // MARK: - Helper Methods

    /// Checks if this is the user's first app launch and shows instructions if needed
    /// Uses DataManager to check UserDefaults for previous launch history
    private func checkFirstLaunch() {
        if !DataManager.shared.hasLaunchedBefore() {
            showInstructions = true
        }
    }
    
    /// Resets pagination and fetches fresh classroom data from Firestore
    /// Called when user changes filters, sorts, or pulls to refresh
    private func updateQuery() {
        print("🔄 [ClassroomsView] Starting data refresh")

        // Reset pagination state to start fresh
        provider.resetPagination()
        
        // Fetch new data with current parameters
        provider.getClassData(
            userId: userId,
            descendingOrder: isDescending,
            getClassesWithTeacherRole: getClassesWithTeacherRole,
            isRefreshing: true
        )
    }
    
    /// Triggers pagination if the user has scrolled to the last item
    /// Prevents duplicate requests and checks for more available data
    /// - Parameter current: The classroom item that just appeared on screen
    private func loadMoreIfNeeded(current: Classroom) {
        guard let last = provider.classrooms.last,
              last.id == current.id,
              provider.hasMoreData,
              !isPaginating else { return }
            
        provider.getClassData(
            userId: userId,
            descendingOrder: isDescending,
            getClassesWithTeacherRole: getClassesWithTeacherRole
        )
        
        print("⏳ [ClassroomsView] Pagination request sent")
    }
    
    /// Dismisses the on-screen keyboard when user taps the keyboard dismiss button
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Preview Provider

#Preview {
    ClassroomsView(
        userId: "3rNFDKJebENEfHqVFg475bJXb9j1"
    )
}
