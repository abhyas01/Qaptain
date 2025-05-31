//
//  ClassMembersView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/30/25.
//

import SwiftUI

/// Displays and manages all members (students and teachers) within a specific classroom
/// This view provides functionality for viewing classroom enrollment, searching through members,
/// and allowing classroom creators to remove members when necessary.
///
/// Key Features:
/// - Real-time member list with search functionality
/// - Role-based permissions (creators can remove members)
/// - Pull-to-refresh for updated member data
/// - Error handling with retry mechanisms
/// - Loading states and empty state handling
/// - Member removal with immediate UI updates
struct ClassMembersView: View {
    
    // MARK: - Properties

    /// Unique identifier for the classroom whose members are being displayed
    /// Used for all Firestore database operations related to this classroom
    let classroomId: String
    
    /// Boolean indicating if the current user created this classroom
    /// Determines UI permissions - creators can remove members, students cannot
    let isCreator: Bool
    
    // MARK: - State Properties

    /// Array containing all members currently enrolled in the classroom
    /// Populated from Firestore and updated when members are added/removed
    @State private var members: [Member] = []
    
    /// Search query string for filtering members by name or email
    /// Updated in real-time as user types in the search bar
    @State private var query: String = ""
    
    /// Loading state indicator for network operations
    /// Shows progress indicator while fetching member data from Firestore
    @State private var isLoading: Bool = false
    
    /// Error state indicator for failed network operations
    /// Triggers error UI with retry option when member fetching fails
    @State private var isError: Bool = false
    
    // MARK: - Computed Properties

    /// Filtered array of members based on current search query
    /// Searches through both member names and email addresses (case-insensitive)
    /// Returns all members when query is empty
    private var filteredMembers: [Member] {
        
        // Log search operation for debugging
        let _ = print("🔍 ClassMembersView: Filtering members with query: '\(query)'")
        
        if query.isEmpty {
            
            // Query is empty therefore we return all members
            print("📋 ClassMembersView: Showing all \(members.count) members (no filter applied)")
            return members
            
        } else {
            let filtered = members.filter {
                $0.name.localizedCaseInsensitiveContains(query) ||
                $0.email.localizedCaseInsensitiveContains(query)
            }
            
            print("🔎 ClassMembersView: Found \(filtered.count) members matching query '\(query)'")
            return filtered
        }
    }
    
    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack {
                List {
                    
                    // Error State Handling
                    if !isError {
                        
                        // Empty State or Member List
                        if filteredMembers.isEmpty {
                            if !isLoading {
                                
                                // Display appropriate empty state message
                                Text(query.isEmpty ? "No members in this classroom yet." : "No member matches your search query")
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            
                            // Member List Display
                            ForEach(filteredMembers, id: \.userId) { member in
                                MemberCell(
                                    member: member,
                                    isRemovable: isCreator && !member.isCreator,
                                    classroomId: classroomId
                                ) { memberUserId in
                                    members.removeAll { $0.userId == memberUserId }
                                }
                                .listRowSeparator(.hidden)
                            }
                        }
                        
                        // Loading State Display
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
                        
                        // Error State Display
                        VStack {
                            Text("An error occured while fetching members.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            
                            Button {
                                
                                // Log retry attempt
                                print("🔄 ClassMembersView: User initiated retry for member fetching")
                                fetchMembers()
                                
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
                
                // Pull-to-Refresh Implementation
                .refreshable {
                    fetchMembers()
                    
                    // Add small delay for better user experience
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
                
                // Search Functionality
                .searchable(text: $query)
            }
            
            // Navigation Toolbar Configuration
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("Class Members")
                    }
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.orange)
                    .fontWeight(.bold)
                }
            }
            
            // View Lifecycle
            .onAppear {
                print("🚀 ClassMembersView: View appeared, initiating member fetch")
                fetchMembers()
            }
            
            .tint(.orange)
            .accentColor(.orange)
        }
    }
    
    // MARK: - Private Methods

    /// Fetches all members of the current classroom from Firestore
    /// Updates the UI state based on success/failure of the operation
    /// Handles loading states and error conditions appropriately
    private func fetchMembers() {
        print("📡 ClassMembersView: Starting member fetch for classroom: \(classroomId)")

        // Update UI to show loading state
        withAnimation {
            isLoading = true
            isError = false
        }
        
        DataManager.shared.getAllMembers(classroomId: classroomId) { result in
            
            // Ensure UI updates happen on main thread
            DispatchQueue.main.async {
                withAnimation {
                    isLoading = false
                    if let members = result {
                        
                        self.members = members
                        print("✅ ClassMembersView: Successfully loaded \(members.count) members")

                    } else {
                        
                        isError = true
                        print("❌ ClassMembersView: Failed to fetch members, showing error state")
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ClassMembersView(
        classroomId: "gQatY3SaHOLK8vd9EUtl",
        isCreator: true
    )
}
