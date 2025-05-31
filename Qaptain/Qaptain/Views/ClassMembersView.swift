//
//  ClassMembersView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/30/25.
//

import SwiftUI

struct ClassMembersView: View {
    
    let classroomId: String
    let isCreator: Bool
    
    @State private var members: [Member] = []
    @State private var query: String = ""
    @State private var isLoading: Bool = false
    @State private var isError: Bool = false
    
    private var filteredMembers: [Member] {
        if query.isEmpty {
            return members
        } else {
            return members.filter { $0.name.localizedCaseInsensitiveContains(query) || $0.email.localizedCaseInsensitiveContains(query) }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                List {
                    if !isError {
                        
                        if filteredMembers.isEmpty {
                            if !isLoading {
                                Text(query.isEmpty ? "No members in this classroom yet." : "No member matches your search query")
                                    .multilineTextAlignment(.center)
                                    .frame(maxWidth: .infinity)
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
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
                            Text("An error occured while fetching members.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                            Button {
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
                .refreshable {
                    fetchMembers()
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                }
                .searchable(text: $query)
            }
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
            .onAppear(perform: fetchMembers)
            .tint(.orange)
            .accentColor(.orange)
        }
    }
    
    private func fetchMembers() {
        withAnimation {
            isLoading = true
            isError = false
        }
        DataManager.shared.getAllMembers(classroomId: classroomId) { result in
            DispatchQueue.main.async {
                withAnimation {
                    isLoading = false
                    if let members = result {
                        self.members = members
                    } else {
                        isError = true
                    }
                }
            }
        }
    }
}

#Preview {
    ClassMembersView(
        classroomId: "gQatY3SaHOLK8vd9EUtl",
        isCreator: true
    )
}
