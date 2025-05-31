//
//  ClassroomProvider.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/23/25.
//

import SwiftUI
import FirebaseFirestore

/// Singleton class responsible for fetching, caching, and managing classroom data from Firestore
/// Handles paginated loading of classrooms with real-time updates and error management
/// Provides filtered access to classrooms based on user role (teacher vs student)
/// Implements ObservableObject pattern for SwiftUI view updates and state management
class ClassroomProvider: ObservableObject {
    
    // MARK: - Singleton Instance

    /// Shared singleton instance ensures consistent classroom data across the entire application
    /// Prevents duplicate network requests and maintains centralized state management
    static let shared = ClassroomProvider()
    
    // MARK: - Published Properties

    /// Array of classroom objects currently loaded and available for display
    /// Observed by SwiftUI views to trigger automatic UI updates when data changes
    @Published var classrooms: [Classroom] = []
    
    /// Loading state indicator for network operations and data fetching
    /// Used by UI to show progress indicators and disable user interactions during loading
    @Published var isLoading = false
    
    /// Error state indicator for failed network requests or data processing errors
    /// Triggers error UI display and retry mechanisms in connected views
    @Published var isError = false
    
    // MARK: - Pagination Properties

    /// Flag indicating whether more classroom data is available for pagination
    /// Prevents unnecessary network requests when all data has been loaded
    var hasMoreData = true
    
    /// Reference to the last Firestore document retrieved for pagination cursor
    /// Used to continue fetching from the correct position in subsequent requests
    private var lastDocument: DocumentSnapshot?
    
    // MARK: - Initialization

    /// Private initializer enforces singleton pattern and prevents external instantiation
    /// Initializes with empty state ready for first data fetch operation
    private init() {}
    
    // MARK: - Data Fetching Methods

    /// Fetches classroom data from Firestore with pagination and filtering capabilities
    /// Constructs complex queries based on user role and sorting preferences
    /// - Parameters:
    ///   - userId: Unique identifier of the user requesting classroom data
    ///   - descendingOrder: Sort order for classroom creation dates (true = newest first)
    ///   - getClassesWithTeacherRole: Filter for teacher-created classes (true) vs enrolled classes (false)
    ///   - isRefreshing: Whether this is a refresh operation (resets pagination)
    ///   - pageSize: Number of classrooms to fetch per request for pagination control
    func getClassData(
        userId: String,
        descendingOrder: Bool,
        getClassesWithTeacherRole: Bool,
        isRefreshing: Bool = false,
        pageSize: Int = 30
    ) {
        print("🔍 Starting classroom data fetch")
        print("👤 User ID: \(userId)")
        print("📈 Sort order: \(descendingOrder ? "descending" : "ascending")")
        print("👨‍🏫 Teacher role filter: \(getClassesWithTeacherRole)")
        print("🔄 Is refreshing: \(isRefreshing)")
        print("📄 Page size: \(pageSize)")
        
        // Reset error state and show loading indicator
        self.removeError()
        self.showSpinner()
        
        // Build Firestore query starting with collection group for cross-classroom member search
        var query: Query = Firestore
            .firestore()
            .collectionGroup("members")
            .whereField("userId", isEqualTo: userId)
        
        print("🔍 Base query created: collectionGroup('members').whereField('userId', isEqualTo: '\(userId)')")

        // Apply role-based filtering for teacher vs student classrooms
        query = getClassesWithTeacherRole
            ? query.whereField("isCreator", isEqualTo: true)
            : query.whereField("isCreator", isEqualTo: false)
        
        print("🎭 Role filter applied: isCreator = \(getClassesWithTeacherRole)")

        // Apply sorting and pagination constraints
        query = query
            .order(by: "classroomCreatedAt", descending: descendingOrder)
            .limit(to: pageSize + 1)
        
        print("📊 Query configured: order by classroomCreatedAt \(descendingOrder ? "DESC" : "ASC"), limit \(pageSize + 1)")

        // Apply pagination cursor if continuing from previous fetch
        if let lastDoc = self.lastDocument, !isRefreshing {
            print("📄 Pagination cursor applied: starting after document \(lastDoc.documentID)")
            query = query.start(afterDocument: lastDoc)
        }
        
        // Execute Firestore query with error handling and response processing
        query.getDocuments { [weak self] snapshot, error in
            
            guard let self = self else { return }
            
            // Handle Firestore query errors
            guard var docs = snapshot?.documents else {
                self.showError()
                self.stopSpinner()
                return
            }
            
            print("✅ Query successful: retrieved \(docs.count) member documents")

            // Check if more data is available by examining extra document
            self.hasMoreData = docs.count > pageSize
            
            if self.hasMoreData {
                docs.removeLast()
                print("📄 More data available: removed extra document, processing \(docs.count) documents")
            }

            // Update pagination cursor for next fetch
            self.lastDocument = docs.last
            
            // Extract classroom document references from member documents
            let classroomRefs = docs.compactMap { $0.reference.parent.parent }
            
            print("🏫 Extracted \(classroomRefs.count) classroom references from member documents")

            // Fetch actual classroom data using parallel requests
            var classroomMap: [String: Classroom] = [:]
            let group = DispatchGroup()
            
            print("🔄 Starting parallel classroom document fetches")

            // Fetch each classroom document in parallel for better performance
            for ref in classroomRefs {
                group.enter()
                
                print("📄 Fetching classroom document: \(ref.documentID)")

                ref.getDocument { docSnapshot, _ in
                    
                    if let docSnapshot,
                       docSnapshot.exists,
                       let classroom = try? docSnapshot.data(as: Classroom.self) {
                        
                        print("✅ Successfully parsed classroom: \(classroom.classroomName) (ID: \(docSnapshot.documentID))")
                        classroomMap[docSnapshot.documentID] = classroom
                    }
                    
                    group.leave()
                }
            }
            
            // Process results when all parallel fetches complete
            group.notify(queue: .main) {
                print("🏁 All classroom fetches completed")

                // Maintain original order from query results
                let orderedClassrooms = classroomRefs.compactMap { classroomMap[$0.documentID] }
                
                // Update UI with fetched data
                withAnimation {
                    if isRefreshing {
                        
                        print("🔄 Refresh: replacing existing \(self.classrooms.count) classrooms with \(orderedClassrooms.count) new ones")
                        self.classrooms = orderedClassrooms
                        
                    } else {
                        
                        print("📄 Pagination: appending \(orderedClassrooms.count) classrooms to existing \(self.classrooms.count)")
                        self.classrooms += orderedClassrooms
                    }
                }
                
                print("✅ UI updated successfully: total classrooms now \(self.classrooms.count)")
                self.stopSpinner()
            }
        }
    }
    
    // MARK: - Pagination Management

    /// Resets pagination state to prepare for fresh data fetch
    /// Clears existing data and pagination cursor for complete refresh operation
    func resetPagination() {
        print("🔄 Resetting pagination state")

        self.lastDocument = nil
        
        DispatchQueue.main.async {
            withAnimation {
                self.classrooms = []
            }
        }
    }
    
    // MARK: - UI State Management

    /// Updates UI to display error state when data fetching fails
    /// Triggers error UI components and disables loading indicators
    private func showError() {
        DispatchQueue.main.async {
            withAnimation {
                self.isError = true
            }
        }
    }
    
    /// Clears error state from UI to prepare for new operations
    /// Removes error indicators and allows normal UI interaction
    private func removeError() {
        DispatchQueue.main.async {
            withAnimation {
                self.isError = false
            }
        }
    }
    
    /// Activates loading state in UI to indicate ongoing network operations
    /// Shows progress indicators and disables user interactions during data fetch
    private func showSpinner() {
        DispatchQueue.main.async {
            withAnimation {
                self.isLoading = true
            }
        }
    }
    
    /// Deactivates loading state when data operations complete
    /// Hides progress indicators and re-enables user interactions
    private func stopSpinner() {
        DispatchQueue.main.async {
            withAnimation {
                self.isLoading = false
            }
        }
    }
}
