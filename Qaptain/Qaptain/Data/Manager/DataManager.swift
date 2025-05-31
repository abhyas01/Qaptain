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
    
    func removeMember(
        classroomId: String,
        userId: String,
        completion: @escaping (Bool) -> Void
    ) {
        let db = Firestore.firestore()
        let memberRef = db
            .collection("classrooms")
            .document(classroomId)
            .collection("members")
            .document(userId)
        
        Task {
            do {
                try await memberRef.delete()
                
                let quizzesSnapshot = try await db
                    .collection("classrooms")
                    .document(classroomId)
                    .collection("quizzes")
                    .getDocuments()
                
                for quizDoc in quizzesSnapshot.documents {
                    let statsRef = quizDoc.reference.collection("stats").document(userId)
                    try? await statsRef.delete()
                }
                
                completion(true)
                
            } catch {
                
                completion(false)
            }
        }
    }
    
    func getAllMembers(
        classroomId: String,
        completion: @escaping ([Member]?) -> Void
    ) {
        let db = Firestore.firestore()
        
        db.collection("classrooms")
            .document(classroomId)
            .collection("members")
            .getDocuments { snapshot, error in
                
                if let _ = error {
                    completion(nil)
                    return
                }
                
                let members = snapshot?.documents.compactMap { doc -> Member? in
                    try? doc.data(as: Member.self)
                }
                completion(members)
            }
    }
    
    func createClassroom(
        userId: String,
        withClassroomName classroomName: String,
        completionHandler: @escaping (_: Bool?) -> Void
    ) {
        let cleanedClassroomName = self.cleanName(withName: classroomName)
        
        
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
    
    func deleteClassroom(
        classroomId: String,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let db = Firestore.firestore()
        let classroomRef = db.collection("classrooms").document(classroomId)

        Task {
            do {
                
                // Delete all quizzes and their subcollections (quizQuestions, stats)
                let quizzesSnapshot = try await classroomRef.collection("quizzes").getDocuments()
                
                for quizDoc in quizzesSnapshot.documents {
                    
                    // Delete quizQuestions
                    let questionsSnapshot = try await quizDoc.reference.collection("quizQuestions").getDocuments()
                    for qDoc in questionsSnapshot.documents {
                        try await qDoc.reference.delete()
                    }
                    
                    // Delete stats
                    let statsSnapshot = try await quizDoc.reference.collection("stats").getDocuments()
                    for sDoc in statsSnapshot.documents {
                        try await sDoc.reference.delete()
                    }
                    
                    // Delete the quiz doc itself
                    try await quizDoc.reference.delete()
                }

                // Delete all members
                let membersSnapshot = try await classroomRef.collection("members").getDocuments()
                
                for memberDoc in membersSnapshot.documents {
                    try await memberDoc.reference.delete()
                }

                // Delete the classroom document itself
                try await classroomRef.delete()

                completionHandler(true)
            } catch {
                
                completionHandler(false)
            }
        }
    }

    
    func updateClassroomName(
        documentId: String,
        userId: String,
        withName: String,
        completionHandler: @escaping (_: String?) -> Void
    ) {
        let cleanedName = self.cleanName(withName: withName)

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
                    completionHandler(error == nil ? cleanedName : nil)
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
            completionHandler(error == nil ? newPassword : nil)
        }
    }
    
    // MARK: - Quiz CRUD
    
    func createQuiz(
        classroomId: String,
        quizName: String,
        deadline: Date,
        questions: [LocalQuestion],
        completionHandler: @escaping (_: Bool?) -> Void
    ) {
        let cleanedQuizName = self.cleanName(withName: quizName)
        
        let nameCount = cleanedQuizName.count
        let isValid = (nameCount >= 4 && nameCount <= 60)
        
        guard isValid else {
            completionHandler(false)
            return
        }
        
        self.isQuizNameUniqueForClassroom(
            quizName: cleanedQuizName,
            currentQuizId: nil,
            classroomId: classroomId,
            completion: { isUnique in
                
                guard let isUnique = isUnique else {
                    completionHandler(nil)
                    return
                }
                
                guard isUnique else {
                    completionHandler(false)
                    return
                }
                
                let quizRef = Firestore
                    .firestore()
                    .collection("classrooms")
                    .document(classroomId)
                    .collection("quizzes")
                    .document()
                
                quizRef.setData([
                    "quizName": cleanedQuizName,
                    "createdAt": FieldValue.serverTimestamp(),
                    "deadline": deadline
                ]) { error in
                    
                    if let _ = error {
                        completionHandler(nil)
                        return
                    }
                    
                    let batch = Firestore.firestore().batch()
                    
                    for q in questions {
                        let qRef = quizRef.collection("quizQuestions").document()
                        batch.setData(q.firestoreData, forDocument: qRef)
                    }
                    
                    batch.commit { err in
                        
                        if let _ = err {
                            completionHandler(nil)
                        } else {
                            completionHandler(true)
                        }
                    }
                }
            }
        )
    }
    
    func getAllQuizDocuments(
        classroomId: String,
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
    
    func getAllQuizStatsForAdmin(
        classroomId: String,
        quizId: String,
        isDescending: Bool,
        completionHandler: @escaping ([QuizStat]?) -> Void
    ) {
        let docRef = Firestore
            .firestore()
            .collection("classrooms")
            .document(classroomId)
            .collection("quizzes")
            .document(quizId)
            .collection("stats")
            .order(by: "lastAttemptDate", descending: isDescending)
        
        Task {
            do {
                let stats = try await docRef
                    .getDocuments()
                    .documents
                    .compactMap { try? $0.data(as: QuizStat.self) }
                
                completionHandler(stats)
                
            } catch {
                
                completionHandler(nil)
            }
        }
    }
    
    func getQuizStatsForUser(
        classroomId: String,
        quizId: String,
        userId: String,
        completionHandler: @escaping (QuizStat??) -> Void
    ) {
        let docRef = Firestore
            .firestore()
            .collection("classrooms")
            .document(classroomId)
            .collection("quizzes")
            .document(quizId)
            .collection("stats")
            .document(userId)
        
        Task {
            do {
                let snapshot = try await docRef.getDocument()
                
                guard snapshot.exists else {
                    completionHandler(.some(nil))
                    return
                }
                
                let stat = try snapshot.data(as: QuizStat.self)
                completionHandler(.some(stat))
                
            } catch {
                completionHandler(nil)
            }
        }
    }
    
    func updateQuizNameDeadline(
        classroomId: String,
        quizId: String,
        quizName: String,
        deadline: Date,
        createdAt: Date,
        completionHandler: @escaping (_: String?) -> Void
    ) {
        let cleanedQuizName = self.cleanName(withName: quizName)
        
        let nameCount = cleanedQuizName.count
        let isValid = (nameCount >= 4 && nameCount <= 60) && (deadline > createdAt)

        guard isValid else {
            completionHandler(nil)
            return
        }
        
        self.isQuizNameUniqueForClassroom(
            quizName: quizName,
            currentQuizId: quizId,
            classroomId: classroomId,
            completion: { isUnique in
                
                guard let isUnique = isUnique else {
                    completionHandler(nil)
                    return
                }
                
                guard isUnique else {
                    completionHandler(nil)
                    return
                }
                
                let quizRef = Firestore
                    .firestore()
                    .collection("classrooms")
                    .document(classroomId)
                    .collection("quizzes")
                    .document(quizId)
                
                quizRef.updateData([
                    "quizName": cleanedQuizName,
                    "deadline": deadline
                ]) { error in
                    if let _ = error {
                        completionHandler(nil)
                    } else {
                        completionHandler(cleanedQuizName)
                    }
                }
            }
        )
    }
    
    func deleteQuiz(
        classroomId: String,
        quizId: String,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let db = Firestore.firestore()
        
        let quizRef = db
            .collection("classrooms")
            .document(classroomId)
            .collection("quizzes")
            .document(quizId)
        
        Task {
            do {
        
                // Delete quizQuestions subcollection
                let questionsSnapshot = try await quizRef.collection("quizQuestions").getDocuments()
                for doc in questionsSnapshot.documents {
                    try await doc.reference.delete()
                }
                
                // Delete stats subcollection
                let statsSnapshot = try await quizRef.collection("stats").getDocuments()
                for doc in statsSnapshot.documents {
                    try await doc.reference.delete()
                }
                
                // Delete the quiz document itself
                try await quizRef.delete()
                
                completionHandler(true)
                
            } catch {
                completionHandler(false)
            }
        }
    }
    
    func getAllQuestionsFromQuiz(
        classroomId: String,
        quizId: String,
        completionHandler: @escaping ([Question]?) -> Void
    ) {
        let quizQuestionsRef = Firestore
            .firestore()
            .collection("classrooms")
            .document(classroomId)
            .collection("quizzes")
            .document(quizId)
            .collection("quizQuestions")
        
        Task {
            do {
                
                let snapshot = try await quizQuestionsRef.getDocuments()
                let questions: [Question] = snapshot.documents.compactMap { try? $0.data(as: Question.self) }
                
                completionHandler(questions)
                
            } catch {
                
                completionHandler(nil)
            }
        }
    }
    
    func submitStatsForQuiz(
        userId: String,
        classroomId: String,
        quizId: String,
        newAttempt: Attempt,
        completionHandler: @escaping (Bool?) -> Void
    ) {
        let statsRef = Firestore
            .firestore()
            .collection("classrooms")
            .document(classroomId)
            .collection("quizzes")
            .document(quizId)
            .collection("stats")
            .document(userId)
        
        Task {
            do {
                guard let user = await self.getUser(userId: userId) else {
                    completionHandler(nil)
                    return
                }

                let snapshot = try await statsRef.getDocument()

                var stat: QuizStat

                if snapshot.exists, let existing = try? snapshot.data(as: QuizStat.self) {
                    
                    var updatedAttempts = existing.attempts
                    updatedAttempts.append(newAttempt)

                    stat = QuizStat(
                        id: userId,
                        userId: user.userId,
                        email: user.email,
                        name: user.name,
                        lastAttemptDate: newAttempt.attemptDate,
                        attempts: updatedAttempts
                    )
                } else {
                    
                    stat = QuizStat(
                        id: userId,
                        userId: user.userId,
                        email: user.email,
                        name: user.name,
                        lastAttemptDate: newAttempt.attemptDate,
                        attempts: [newAttempt]
                    )
                }

                try statsRef.setData(from: stat, merge: true)

                completionHandler(true)

            } catch {
                print("Failed to submit stat: \(error)")
                completionHandler(false)
            }
        }
    }

    private func isQuizNameUniqueForClassroom(
        quizName: String,
        currentQuizId: String?,
        classroomId: String,
        completion: @escaping (Bool?) -> Void
    ) {
        let db = Firestore.firestore()

        db.collection("classrooms")
            .document(classroomId)
            .collection("quizzes")
            .getDocuments { snapshot, error in
                
                if let _ = error {
                    completion(nil)
                    return
                }
                
                guard let docs = snapshot?.documents else {
                    completion(nil)
                    return
                }

                let cleanedQuizName = quizName
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                
                for doc in docs {
                    guard let quizData = try? doc.data(as: Quiz.self),
                          let quizId = quizData.id else { continue }

                    if quizId != currentQuizId &&
                        cleanedQuizName == quizData.quizName
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .lowercased() {
                        
                        completion(false)
                        return
                    }
                }

                completion(true)
            }
    }

    private func cleanName(withName: String) -> String {
        let trimmedName = withName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        let components = trimmedName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return components.joined(separator: " ")
    }
}
