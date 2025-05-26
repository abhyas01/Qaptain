//
//  ClassroomProvider.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/23/25.
//

import SwiftUI
import FirebaseFirestore

class ClassroomProvider: ObservableObject {
    
    static let shared = ClassroomProvider()
    
    @Published var classrooms: [Classroom] = []
    @Published var isLoading = false
    @Published var hasMoreData = true
    
    private var lastDocument: DocumentSnapshot?
    
    private init() {}
    
    func getClassData(
        userId: String,
        descendingOrder: Bool,
        getClassesWithTeacherRole: Bool,
        isRefreshing: Bool = false,
        pageSize: Int = 30
    ) {
        self.showSpinner()
        
        var query: Query = Firestore
            .firestore()
            .collectionGroup("members")
            .whereField("userId", isEqualTo: userId)
        
        query = getClassesWithTeacherRole
            ? query.whereField("role", isEqualTo: "teacher")
            : query.whereField("role", isEqualTo: "student")
        
        query = query
            .order(by: "classroomCreatedAt", descending: descendingOrder)
            .limit(to: pageSize + 1)
        
        if let lastDoc = self.lastDocument, !isRefreshing {
            query = query.start(afterDocument: lastDoc)
        }
        
        query.getDocuments { [weak self] snapshot, error in
            
            guard let self = self,
                  var docs = snapshot?.documents
            else {
                self?.stopSpinner()
                return
            }
            
            self.hasMoreData = docs.count > pageSize
            
            if self.hasMoreData {
                docs.removeLast()
            }

            self.lastDocument = docs.last
            let classroomRefs = docs.compactMap { $0.reference.parent.parent }
            
            var classroomMap: [String: Classroom] = [:]
            let group = DispatchGroup()
            
            for ref in classroomRefs {
                group.enter()
                
                ref.getDocument { docSnapshot, _ in
                    
                    if let docSnapshot,
                       docSnapshot.exists,
                       let classroom = try? docSnapshot.data(as: Classroom.self) {
                        
                        classroomMap[docSnapshot.documentID] = classroom
                    }
                    
                    group.leave()
                }
            }
            
            group.notify(queue: .main) {
                
                let orderedClassrooms = classroomRefs.compactMap { classroomMap[$0.documentID] }
                
                withAnimation {
                    if isRefreshing {
                        self.classrooms = orderedClassrooms
                    } else {
                        self.classrooms += orderedClassrooms
                    }
                }
                
                self.stopSpinner()
            }
        }
    }
    
    func resetPagination() {
        self.lastDocument = nil
        self.classrooms = []
    }
    
    private func showSpinner() {
        DispatchQueue.main.async {
            withAnimation {
                self.isLoading = true
            }
        }
    }
    
    private func stopSpinner() {
        DispatchQueue.main.async {
            withAnimation {
                self.isLoading = false
            }
        }
    }
}
