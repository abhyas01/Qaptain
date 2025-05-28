//
//  DataManager.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/23/25.
//

import SwiftUI
import FirebaseFirestore

class DataManager {
    
    static let shared = DataManager()
    
    private init() {}
    
    // MARK: - User Account Functions
    
    func getUser(
        userId: String
    ) async -> User? {
        do {
            let user = try await Firestore
                .firestore()
                .collection("users")
                .document(userId)
                .getDocument(as: User.self)
            
            return user
        } catch {
            return nil
        }
    }
    
    // MARK: - Classroom CRUD
    
    func joinClassroom(
        userId: String,
        password: String,
        completionHandler: @escaping (_: Bool?) -> Void
    ) {
        
        let query = Firestore
            .firestore()
            .collection("classrooms")
            .whereField(
                "password",
                isEqualTo: password
            )
            .limit(to: 1)
        
        Task { [weak self] in
            do {
                
                guard let self = self else {
                    completionHandler(nil)
                    return
                }
                
                let snapshot = try await query.getDocuments()
                
                guard let document = snapshot.documents.first else {
                    completionHandler(false)
                    return
                }
                
                let classroomData = try document.data(as: Classroom.self)
                
                guard let classroomId = classroomData.id,
                      let createdAt = classroomData.createdAt else {
                    completionHandler(nil)
                    return
                }
                
                let memberRef = Firestore
                    .firestore()
                    .collection("classrooms")
                    .document(classroomId)
                    .collection("members")
                    .document(userId)
                
                let existingMember = try await memberRef.getDocument()
                
                if existingMember.exists {
                    completionHandler(false)
                    return
                }
                
                let user = await self.getUser(userId: userId)
                
                guard let user = user else {
                    completionHandler(nil)
                    return
                }
                
                let memberData: [String: Any] = [
                    "userId": userId,
                    "classroomCreatedAt": createdAt,
                    "email": user.email,
                    "name": user.name,
                    "isCreator": false
                ]
                
                try await memberRef.setData(memberData)
                
                completionHandler(true)
                
            } catch {
                
                completionHandler(nil)
                
            }
        }
    }
    
    func createClassroom(
        userId: String,
        withClassroomName classroomName: String,
        completionHandler: @escaping (_: Bool?) -> Void
    ) {
        let cleanedClassroomName = self.cleanClassroomName(withName: classroomName)
        
        
        guard self.validateLengthOfClassroomName(name: cleanedClassroomName) else {
            completionHandler(false)
            return
        }
        
        self.isClassroomUniqueForCreator(
            userId: userId,
            newName: cleanedClassroomName,
            currentClassroomId: nil,
            completion: { isUnique in
                
                guard let isUnique = isUnique else {
                    completionHandler(nil)
                    return
                }
                
                guard isUnique else {
                    completionHandler(false)
                    return
                }
                
                Task { [weak self] in
                    guard let self = self else { return }
                    
                    // Step 1 -> Get User data
                    guard let user = await self.getUser(userId: userId) else {
                        completionHandler(nil)
                        return
                    }
                    
                    // Step 2 -> Prepare classroom data
                    let db = Firestore.firestore()
                    let newClassroomRef = db.collection("classrooms").document()
                    
                    let classroomData: [String: Any] = [
                        "classroomName": cleanedClassroomName,
                        "createdAt": FieldValue.serverTimestamp(),
                        "createdByName": user.name,
                        "password": UUID().uuidString
                    ]
                    
                    do {
                        // Step 3 -> Create Classroom
                        try await newClassroomRef.setData(classroomData)
                        
                        let snapshot = try await newClassroomRef.getDocument()
                        
                        guard let data = snapshot.data(),
                              let createdAt = data["createdAt"] as? Timestamp else {
                            completionHandler(nil)
                            return
                        }
                        
                        // Step 4 -> Prepare Member Data
                        let memberData: [String: Any] = [
                            "userId": userId,
                            "email": user.email,
                            "name": user.name,
                            "isCreator": true,
                            "classroomCreatedAt": createdAt.dateValue()
                        ]
                        
                        // Step 5 -> Create Member
                        try await newClassroomRef
                            .collection("members")
                            .document(userId)
                            .setData(memberData)
                        
                        completionHandler(true)
                        
                    } catch {
                        
                        completionHandler(nil)
                    }
                }
            }
        )
    }
    
    func updateClassroomName(
        documentId: String,
        userId: String,
        withName: String,
        completionHandler: @escaping (_: String?) -> Void
    ) {
        let cleanedName = self.cleanClassroomName(withName: withName)

        guard self.validateLengthOfClassroomName(name: cleanedName) else {
            completionHandler(nil)
            return
        }
        
        self.isClassroomUniqueForCreator(
            userId: userId,
            newName: cleanedName,
            currentClassroomId: documentId
        ) { isUnique in
            guard let isUnique = isUnique else {
                completionHandler(nil)
                return
            }

            guard isUnique else {
                completionHandler(nil)
                return
            }

            Firestore
                .firestore()
                .collection("classrooms")
                .document(documentId)
                .updateData(["classroomName": cleanedName]) { error in
                    DispatchQueue.main.async {
                        withAnimation {
                            completionHandler(error == nil ? cleanedName : nil)
                        }
                    }
                }
        }
    }
    
    private func isClassroomUniqueForCreator(
        userId: String,
        newName: String,
        currentClassroomId: String?,
        completion: @escaping (Bool?) -> Void
    ) {
        let db = Firestore.firestore()
        
        db.collectionGroup("members")
            .whereField("userId", isEqualTo: userId)
            .whereField("isCreator", isEqualTo: true)
            .getDocuments { snapshot, error in
                
                if let _ = error {
                    completion(nil)
                    return
                }
                
                guard let docs = snapshot?.documents else {
                    completion(nil)
                    return
                }
                
                let syncQueue = DispatchQueue(label: "isUnique.sync")
                let dispatchGroup = DispatchGroup()
                
                var isUnique = true
                let cleanedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
                for doc in docs {
                    
                    guard isUnique else { break }
                    
                    guard let classroomRef = doc.reference.parent.parent else {
                        continue
                    }
                    
                    dispatchGroup.enter()
                    
                    classroomRef.getDocument { classroomDoc, error in
                        
                        if let classroomDoc = classroomDoc,
                           ((currentClassroomId == nil) || (classroomDoc.documentID != currentClassroomId)),
                           let name = classroomDoc.get("classroomName") as? String {
                            
                            if name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ==
                                cleanedNewName {
                                
                                syncQueue.sync {
                                    isUnique = false
                                }
                            }
                        }
                        
                        dispatchGroup.leave()
                    }
                }
                
                dispatchGroup.notify(queue: .main) {
                    completion(isUnique)
                }
            }
    }
    
    private func cleanClassroomName(withName: String) -> String {
        let trimmedName = withName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let components = trimmedName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return components.joined(separator: " ")
    }
    
    private func validateLengthOfClassroomName(name: String) -> Bool {
        let count = name.count

        guard !name.isEmpty, count >= 8, count <= 150 else {
            return false
        }
        
        return true
    }
    
    func regenerateClassroomPassword(
        documentId: String,
        completionHandler: @escaping (_: String?) -> Void
    ) {
        let newPassword = UUID().uuidString
        
        let passwordData = ["password": newPassword]
        
        let docRef = Firestore
            .firestore()
            .collection("classrooms")
            .document(documentId)
        
        docRef.updateData(passwordData) { error in
            
            DispatchQueue.main.async {
                withAnimation {
                    completionHandler(error == nil ? newPassword : nil)
                }
            }
        }
    }
    
    // MARK: - Quiz CRUD
    
    func getAllQuizDocuments(
        classroomId: String,
        userId: String,
        isDescending: Bool,
        sortByDeadline: Bool,
        completionHandler: @escaping ([Quiz]?) -> Void
    ) {
       let classroomRef = Firestore
            .firestore()
            .collection("classrooms")
            .document(classroomId)
            .collection("quizzes")
            .order(by: sortByDeadline ? "deadline" : "createdAt", descending: isDescending)
        
        Task {
            do {
                
                let snapshot = try await classroomRef.getDocuments()
                let quizData = snapshot.documents.compactMap { try? $0.data(as: Quiz.self) }
                
                completionHandler(quizData)
                
            } catch {
                
                completionHandler(nil)
            }
        }
    }
}
