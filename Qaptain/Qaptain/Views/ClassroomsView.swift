//
//  ClassroomsView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/23/25.
//

import SwiftUI

struct ClassroomsView: View {

    @StateObject private var provider: ClassroomProvider = ClassroomProvider.shared
    let userId: String
    
    private enum ClassOptions: CaseIterable {
        case enrolledClasses
        case teachingClasses
        
        var getString: String {
            switch self {
            case .enrolledClasses:
                return "Enrolled Classes"
            case .teachingClasses:
                return "Teaching Classes"
            }
        }
    }
    
    @State private var query: String = ""
    @State private var classSelection: ClassOptions = .enrolledClasses
    @State private var isDescending: Bool = true
    
    private var isPaginating: Bool {
        provider.isLoading || provider.classrooms.isEmpty
    }
    
    private var getClassesWithTeacherRole: Bool {
        classSelection == .teachingClasses ? true : false
    }
    
    private var classrooms: [Classroom] {
        let classrooms = provider.classrooms
        
        if query.isEmpty {
            return classrooms
        } else {
            let monthDateFormatter = DateFormatter()
            monthDateFormatter.dateFormat = "MMMM yyyy"
            
            return classrooms.filter { classroom in
                let nameMatch = classroom.classroomName.localizedCaseInsensitiveContains(query)
                
                var dateMatch = false
                
                if let createdAt = classroom.createdAt {
                    let monthYear = monthDateFormatter.string(from: createdAt)
                    dateMatch = monthYear.localizedCaseInsensitiveContains(query)
                }
                
                let teacherMatch = classroom.createdByName.localizedCaseInsensitiveContains(query)
                
                return nameMatch || dateMatch || teacherMatch
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                
                Picker("Class Type",
                       selection: $classSelection
                ) {
                    ForEach(ClassOptions.allCases, id: \.self) { option in
                        Text(option.getString)
                    }
                }
                .pickerStyle(.segmented)
                
                List {
                    
                    if classrooms.isEmpty {
                        
                        if !provider.isLoading {
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
                        }
                        
                    } else {
                        
                        ForEach(classrooms) { classroom in
                            if let id = classroom.id,
                               let createdAt = classroom.createdAt {
                                
                                NavigationLink {
                                    ClassroomDetailView(
                                        userId: userId,
                                        documentId: id,
                                        classroomName: classroom.classroomName,
                                        createdAt: createdAt,
                                        createdByName: classroom.createdByName,
                                        admin: getClassesWithTeacherRole
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
                    
                    if provider.isLoading {
                        HStack {
                            Text("Loading...")
                            ProgressView()
                        }
                        .frame(maxWidth: .infinity)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                    }
                }
                .listRowSpacing(25)
                .refreshable {
                    updateQuery()
                    try? await Task.sleep(
                        nanoseconds: UInt64(500_000_000)
                    )
                }
                .searchable(text: $query)
                
                VStack {
                    Button {
                        
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(
                        getClassesWithTeacherRole ?
                            "Teaching Classes" :
                            "Enrolled Classes"
                    )
                    .font(.title3)
                    .fontDesign(.rounded)
                    .foregroundStyle(.orange)
                    .fontWeight(.bold)
                }
                
                if !classrooms.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        sortButton
                    }
                }
            }
            .onAppear {
                updateQuery()
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
    
    private var sortButton: some View {
        Menu {
            
            Section("Sort By Date"){
                Button {
                    isDescending = true
                    updateQuery()
                } label: {
                    HStack {
                        Text("Descending Order")
                        if isDescending {
                            Spacer()
                            Image(systemName: "checkmark")
                        }
                    }
                }
                
                Button {
                    isDescending = false
                    updateQuery()
                } label: {
                    HStack {
                        Text("Ascending Order")
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
    
    private func updateQuery() {
        provider.resetPagination()
        
        provider.getClassData(
            userId: userId,
            descendingOrder: isDescending,
            getClassesWithTeacherRole: getClassesWithTeacherRole,
            isRefreshing: true
        )
    }
    
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
    }
}

#Preview {
    ClassroomsView(
        userId: "3rNFDKJebENEfHqVFg475bJXb9j1"
    )
}
