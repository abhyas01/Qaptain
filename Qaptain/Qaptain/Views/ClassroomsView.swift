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
    
    @State private var showCreateNewClassroom: Bool = false
    @State private var showEnrollNewClassroom: Bool = false
    
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
                        
                        if !provider.isError {
                            
                            if classrooms.isEmpty {
                                
                                if !provider.isLoading {
                                    
                                    if query.isEmpty {
                                        
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
                                        
                                        Text("Cannot find any class that matches your search query")
                                            .multilineTextAlignment(.center)
                                            .frame(maxWidth: .infinity)
                                            .font(.footnote)
                                            .foregroundStyle(.secondary)
                                    }
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
                            
                            if provider.isLoading {
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
                                Text("An error occured while fetching classrooms.")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                                
                                Button {
                                    updateQuery()
                                } label: {
                                    Text("Retry?")
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                
                    .sheet(isPresented: $showCreateNewClassroom) {
                        CreateClassroomSheet(userId: userId) {
                            updateQuery()
                        }
                    }
                
                    .sheet(isPresented: $showEnrollNewClassroom) {
                        EnrollClassroomSheet(userId: userId) {
                            updateQuery()
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
                        
                        if getClassesWithTeacherRole {
                            
                            showCreateNewClassroom = true
                            
                        } else {
                            
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
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "book.circle")
                        
                        Text(
                            getClassesWithTeacherRole ?
                            "Teaching Classes" :
                                "Enrolled Classes"
                        )
                    }
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
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

#Preview {
    ClassroomsView(
        userId: "3rNFDKJebENEfHqVFg475bJXb9j1"
    )
}
