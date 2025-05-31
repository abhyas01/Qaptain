//
//  DataManager.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/23/25.
//

import SwiftUI
import FirebaseFirestore

/// Singleton class responsible for managing all Firebase Firestore database operations
/// This class handles CRUD operations for users, classrooms, quizzes, questions, and quiz statistics
/// Uses Firebase Firestore as the backend database and provides completion handlers for asynchronous operations
class DataManager {
    
    // MARK: - Singleton Instance

    /// Shared singleton instance to ensure only one DataManager exists throughout the app lifecycle
    static let shared = DataManager()
    
    /// Private initializer to enforce singleton pattern and prevent external instantiation
    private init() {}
    
    // MARK: - Constants

    /// Internal keys used for UserDefaults storage to track app launch state
    private enum Keys {
        static let hasLaunchedBefore = "has-launched-qaptain-before"
    }
    
    // MARK: - App Launch Management

    /// Checks if the app has been launched before by reading UserDefaults
    /// Used to determine whether to show onboarding/instructions
    /// - Returns: Boolean indicating if app was previously launched
    func hasLaunchedBefore() -> Bool {
        print("📱 Checking if app has been launched before")
        return UserDefaults.standard.bool(forKey: Keys.hasLaunchedBefore)
    }
    
    /// Marks the app as having been launched to prevent showing instructions again
    /// Called after user sees the instructions for the first time
    func markAppAsLaunched() {
        print("📱 Marking app as launched in UserDefaults")
        UserDefaults.standard.set(true, forKey: Keys.hasLaunchedBefore)
    }
    
    // MARK: - User Account Functions
    
    /// Retrieves user data from Firestore using their unique user ID
    /// Used throughout the app to get user name and email for display and operations
    /// - Parameter userId: The unique Firebase Auth user ID
    /// - Returns: User model object if found, nil if user doesn't exist or error occurs
    func getUser(
        userId: String
    ) async -> User? {
        
        print("👤 Fetching user data for ID: \(userId)")
        
        do {
            
            // Query Firestore users collection for the specific user document
            let user = try await Firestore
                .firestore()
                .collection("users")
                .document(userId)
                .getDocument(as: User.self)
            
            print("✅ Successfully retrieved user: \(user.name) (\(user.email))")
            return user
            
        } catch {
            
            print("❌ Failed to retrieve user data: \(error.localizedDescription)")
            return nil
        }
    }
    
    /// Updates the user's name everywhere it exists in the Firestore database.
    /// - Parameters:
    ///   - userId: The user ID whose name should be updated.
    ///   - newName: The new name to set.
    ///   - completionHandler: Callback with `true` if all updates succeed, `false` otherwise.
    func updateUserNameEverywhere(
        userId: String,
        newName: String,
        completionHandler: @escaping (Bool) -> Void
    ) {
        let db = Firestore.firestore()
        Task {
            do {
                // 1. Update name in the main 'users' collection.
                try await db.collection("users").document(userId).updateData([
                    "name": newName
                ])
                print("[updateUserNameEverywhere] Updated name in users collection for userId: \(userId)")

                // 2. Find all member documents across all classrooms for this user.
                let membersSnapshot = try await db
                    .collectionGroup("members")
                    .whereField("userId", isEqualTo: userId)
                    .getDocuments()
                print("[updateUserNameEverywhere] Fetched \(membersSnapshot.documents.count) member docs.")

                var updateTasks: [() async throws -> Void] = []
                
                // Iterate over each member document.
                for doc in membersSnapshot.documents {
                    let memberRef = doc.reference
                    let data = doc.data()
                    // The parent of the 'members' collection is the classroom document.
                    guard let classroomRef = memberRef.parent.parent else {
                        print("[updateUserNameEverywhere] Skipped member doc without classroom parent: \(doc.documentID)")
                        continue // skip invalid member docs
                    }

                    // a. Update name in member document.
                    updateTasks.append {
                        try await memberRef.updateData(["name": newName])
                        print("[updateUserNameEverywhere] Updated member name for doc: \(doc.documentID)")
                    }
                    
                    // b. If user is the creator, update 'createdByName' in the classroom doc.
                    if let isCreator = data["isCreator"] as? Bool, isCreator {
                        updateTasks.append {
                            try await classroomRef.updateData(["createdByName": newName])
                            print("[updateUserNameEverywhere] Updated createdByName for classroom: \(classroomRef.documentID)")
                        }
                    }
                    
                    // c. Update user's name in every 'stats' doc for every quiz in this classroom.
                    let quizSnapshot = try await classroomRef.collection("quizzes").getDocuments()
                    for quizDoc in quizSnapshot.documents {
                        let statRef = quizDoc.reference.collection("stats").document(userId)
                        updateTasks.append {
                            do {
                                try await statRef.updateData(["name": newName])
                                print("[updateUserNameEverywhere] Updated name in stats for quiz: \(quizDoc.documentID)")
                            } catch {
                                // Likely missing doc (user never attempted quiz), ignore
                                print("[updateUserNameEverywhere] No stats doc for user in quiz: \(quizDoc.documentID) (ignored)")
                            }
                        }
                    }
                }
                
                // Run all updates concurrently.
                try await withThrowingTaskGroup(of: Void.self) { group in
                    for task in updateTasks {
                        group.addTask { try await task() }
                    }
                    for try await _ in group {}
                }
                print("✅ [updateUserNameEverywhere] All name updates succeeded.")
                completionHandler(true)
            } catch {
                print("[updateUserNameEverywhere] error: \(error)")
                completionHandler(false)
            }
        }
    }
    
    // MARK: - Classroom CRUD Operations

    /// Allows a user to join an existing classroom using a password
    /// This is the primary method students use to enroll in classes
    /// - Parameters:
    ///   - userId: The ID of the user attempting to join
    ///   - password: The classroom password provided by the teacher
    ///   - completionHandler: Callback with result - true: success, false: invalid password/already member, nil: error
    func joinClassroom(
        userId: String,
        password: String,
        completionHandler: @escaping (_: Bool?) -> Void
    ) {
        print("🏫 User \(userId) attempting to join classroom with password: \(password)")

        let query = Firestore
            .firestore()
            .collection("classrooms")
            .whereField(
                "password",
                isEqualTo: password
            )
            .limit(to: 1) // Only need one matching classroom
        
        Task { [weak self] in
            do {
                
                guard let self = self else {
                    print("❌ DataManager instance deallocated")
                    completionHandler(nil)
                    return
                }
                
                // Execute the query to find classroom with this password
                let snapshot = try await query.getDocuments()
                
                guard let document = snapshot.documents.first else {
                    print("❌ No classroom found with password: \(password)")
                    completionHandler(false)
                    return
                }
                
                // Parse the classroom data from Firestore document
                let classroomData = try document.data(as: Classroom.self)
                
                guard let classroomId = classroomData.id,
                      let createdAt = classroomData.createdAt else {
                    print("❌ Invalid classroom data - missing ID or creation date")
                    completionHandler(nil)
                    return
                }
                
                print("✅ Found classroom: \(classroomData.classroomName) (ID: \(classroomId))")
                
                // Check if user is already a member of this classroom
                let memberRef = Firestore
                    .firestore()
                    .collection("classrooms")
                    .document(classroomId)
                    .collection("members")
                    .document(userId)
                
                let existingMember = try await memberRef.getDocument()
                
                if existingMember.exists {
                    print("❌ User \(userId) is already a member of classroom \(classroomId)")
                    completionHandler(false)
                    return
                }
                
                // Get user data to store in the members collection
                let user = await self.getUser(userId: userId)
                
                guard let user = user else {
                    print("❌ Could not retrieve user data for \(userId)")
                    completionHandler(nil)
                    return
                }
                
                // Prepare member data for Firestore
                let memberData: [String: Any] = [
                    "userId": userId,
                    "classroomCreatedAt": createdAt,
                    "email": user.email,
                    "name": user.name,
                    "isCreator": false
                ]
                
                // Add user as a member to the classroom
                try await memberRef.setData(memberData)
                
                print("✅ Successfully added user \(user.name) to classroom \(classroomData.classroomName)")
                completionHandler(true)
                
            } catch {

                print("❌ Error joining classroom: \(error.localizedDescription)")
                completionHandler(nil)
                
            }
        }
    }
    
    /// Removes a member from a classroom and cleans up their quiz statistics
    /// Used by teachers to remove students or by students to unenroll themselves
    /// - Parameters:
    ///   - classroomId: The ID of the classroom
    ///   - userId: The ID of the user to remove
    ///   - completion: Callback indicating success/failure
    func removeMember(
        classroomId: String,
        userId: String,
        completion: @escaping (Bool) -> Void
    ) {
        print("🗑️ Removing member \(userId) from classroom \(classroomId)")

        let db = Firestore.firestore()
        let memberRef = db
            .collection("classrooms")
            .document(classroomId)
            .collection("members")
            .document(userId)
        
        Task {
            do {
                
                // Remove the member document
                try await memberRef.delete()
                
                // Clean up: Remove user's quiz statistics from all quizzes in this classroom
                let quizzesSnapshot = try await db
                    .collection("classrooms")
                    .document(classroomId)
                    .collection("quizzes")
                    .getDocuments()
                
                print("🧹 Cleaning up quiz stats for \(quizzesSnapshot.documents.count) quizzes")

                for quizDoc in quizzesSnapshot.documents {
                    let statsRef = quizDoc.reference.collection("stats").document(userId)
                    try? await statsRef.delete()
                    print("🗑️ Removed stats for quiz: \(quizDoc.documentID)")
                }
                
                print("✅ Successfully removed member and cleaned up all related data")
                completion(true)
                
            } catch {
                
                print("❌ Error removing member: \(error.localizedDescription)")
                completion(false)
            }
        }
    }
    
    /// Retrieves all members of a specific classroom
    /// Used to display classroom member lists and manage enrollment
    /// - Parameters:
    ///   - classroomId: The ID of the classroom
    ///   - completion: Callback with array of members or nil if error
    func getAllMembers(
        classroomId: String,
        completion: @escaping ([Member]?) -> Void
    ) {
        print("👥 Fetching all members for classroom: \(classroomId)")

        let db = Firestore.firestore()
        
        db.collection("classrooms")
            .document(classroomId)
            .collection("members")
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Error fetching members: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                // Parse member documents into Member objects
                let members = snapshot?.documents.compactMap { doc -> Member? in
                    try? doc.data(as: Member.self)
                }
                
                print("✅ Successfully retrieved \(members?.count ?? 0) members")
                completion(members)
            }
    }
    
    /// Creates a new classroom with the specified user as the creator/teacher
    /// Validates classroom name uniqueness for the creator and sets up initial structure
    /// - Parameters:
    ///   - userId: The ID of the user creating the classroom (becomes the teacher)
    ///   - classroomName: The desired name for the classroom
    ///   - completionHandler: Callback - true: success, false: name conflict/invalid, nil: error
    func createClassroom(
        userId: String,
        withClassroomName classroomName: String,
        completionHandler: @escaping (_: Bool?) -> Void
    ) {
        print("🏫 Creating new classroom '\(classroomName)' for user: \(userId)")

        // Clean and validate the classroom name
        let cleanedClassroomName = self.cleanName(withName: classroomName)
        
        guard self.validateLengthOfClassroomName(name: cleanedClassroomName) else {
            print("❌ Classroom name validation failed: '\(cleanedClassroomName)'")
            completionHandler(false)
            return
        }
        
        // Check if classroom name is unique for this creator
        self.isClassroomUniqueForCreator(
            userId: userId,
            newName: cleanedClassroomName,
            currentClassroomId: nil,
            completion: { isUnique in
                
                guard let isUnique = isUnique else {
                    print("❌ Error checking classroom name uniqueness")
                    completionHandler(nil)
                    return
                }
                
                guard isUnique else {
                    print("❌ Classroom name '\(cleanedClassroomName)' already exists for this user")
                    completionHandler(false)
                    return
                }
                
                Task { [weak self] in
                    guard let self = self else { return }
                    
                    // Step 1: Get User data to store creator information
                    guard let user = await self.getUser(userId: userId) else {
                        print("❌ Could not retrieve user data for classroom creator")
                        completionHandler(nil)
                        return
                    }
                    
                    // Step 2: Prepare classroom data with auto-generated password
                    let db = Firestore.firestore()
                    let newClassroomRef = db.collection("classrooms").document()
                    
                    let classroomData: [String: Any] = [
                        "classroomName": cleanedClassroomName,
                        "createdAt": FieldValue.serverTimestamp(),
                        "createdByName": user.name,
                        "password": UUID().uuidString
                    ]
                    
                    do {
                        
                        // Step 3: Create the classroom document
                        try await newClassroomRef.setData(classroomData)
                        print("✅ Created classroom document with ID: \(newClassroomRef.documentID)")
                        
                        // Get the server timestamp that was just set
                        let snapshot = try await newClassroomRef.getDocument()
                        
                        guard let data = snapshot.data(),
                              let createdAt = data["createdAt"] as? Timestamp else {
                            print("❌ Could not retrieve server timestamp from created classroom")
                            completionHandler(nil)
                            return
                        }
                        
                        // Step 4: Prepare member data for the creator
                        let memberData: [String: Any] = [
                            "userId": userId,
                            "email": user.email,
                            "name": user.name,
                            "isCreator": true,
                            "classroomCreatedAt": createdAt.dateValue()
                        ]
                        
                        // Step 5: Add creator as the first member
                        try await newClassroomRef
                            .collection("members")
                            .document(userId)
                            .setData(memberData)
                        
                        print("✅ Successfully created classroom '\(cleanedClassroomName)")
                        completionHandler(true)
                        
                    } catch {
                        
                        print("❌ Error creating classroom: \(error.localizedDescription)")
                        completionHandler(nil)
                    }
                }
            }
        )
    }
    
    /// Deletes an entire classroom and all associated data (quizzes, members, statistics)
    /// This is a destructive operation that cannot be undone
    /// - Parameters:
    ///   - classroomId: The ID of the classroom to delete
    ///   - completionHandler: Callback indicating success/failure
    func deleteClassroom(
        classroomId: String,
        completionHandler: @escaping (Bool) -> Void
    ) {
        print("🗑️ Deleting classroom: \(classroomId)")

        let db = Firestore.firestore()
        let classroomRef = db.collection("classrooms").document(classroomId)

        Task {
            do {
                
                // Step 1: Delete all quizzes and their subcollections
                let quizzesSnapshot = try await classroomRef.collection("quizzes").getDocuments()
                print("🗑️ Found \(quizzesSnapshot.documents.count) quizzes to delete")

                for quizDoc in quizzesSnapshot.documents {
                    print("🗑️ Deleting quiz: \(quizDoc.documentID)")
                    
                    // Delete quiz questions subcollection
                    let questionsSnapshot = try await quizDoc.reference.collection("quizQuestions").getDocuments()
                    for qDoc in questionsSnapshot.documents {
                        try await qDoc.reference.delete()
                    }
                    
                    print("✅ Deleted \(questionsSnapshot.documents.count) questions")
                    
                    // Delete quiz statistics subcollection
                    let statsSnapshot = try await quizDoc.reference.collection("stats").getDocuments()
                    for sDoc in statsSnapshot.documents {
                        try await sDoc.reference.delete()
                    }
                    
                    print("✅ Deleted \(statsSnapshot.documents.count) stat records")
                    
                    // Delete the quiz document itself
                    try await quizDoc.reference.delete()
                    
                    print("✅ Deleted quiz document")
                }

                // Step 2: Delete all members
                let membersSnapshot = try await classroomRef.collection("members").getDocuments()
                print("🗑️ Found \(membersSnapshot.documents.count) members to delete")

                
                for memberDoc in membersSnapshot.documents {
                    try await memberDoc.reference.delete()
                }
                print("✅ Deleted all member records")

                // Step 3: Delete the classroom document itself
                try await classroomRef.delete()
                print("✅ Successfully deleted classroom and all associated data")

                completionHandler(true)
            } catch {
                
                print("❌ Error deleting classroom: \(error.localizedDescription)")
                completionHandler(false)
            }
        }
    }

    /// Updates the name of an existing classroom after validating uniqueness
    /// Used when teachers want to rename their classrooms
    /// - Parameters:
    ///   - documentId: The ID of the classroom to update
    ///   - userId: The ID of the user making the change (must be creator)
    ///   - withName: The new name for the classroom
    ///   - completionHandler: Callback with new name if successful, nil if failed
    func updateClassroomName(
        documentId: String,
        userId: String,
        withName: String,
        completionHandler: @escaping (_: String?) -> Void
    ) {
        print("✏️ Updating classroom \(documentId) name to: '\(withName)'")

        let cleanedName = self.cleanName(withName: withName)

        guard self.validateLengthOfClassroomName(name: cleanedName) else {
            print("❌ New classroom name validation failed")
            completionHandler(nil)
            return
        }
        
        // Check if new name is unique for this creator
        self.isClassroomUniqueForCreator(
            userId: userId,
            newName: cleanedName,
            currentClassroomId: documentId
        ) { isUnique in
            guard let isUnique = isUnique else {
                print("❌ Error checking name uniqueness")
                completionHandler(nil)
                return
            }

            guard isUnique else {
                print("❌ Classroom name '\(cleanedName)' already exists for this user")
                completionHandler(nil)
                return
            }

            // Update the classroom name in Firestore
            Firestore
                .firestore()
                .collection("classrooms")
                .document(documentId)
                .updateData(["classroomName": cleanedName]) { error in
                    completionHandler(error == nil ? cleanedName : nil)
                }
        }
    }
    
    /// Checks if a classroom name is unique among all classrooms created by a specific user
    /// Teachers cannot have multiple classrooms with the same name
    /// - Parameters:
    ///   - userId: The ID of the user/creator
    ///   - newName: The proposed classroom name
    ///   - currentClassroomId: ID of classroom being edited (excluded from uniqueness check)
    ///   - completion: Callback with true if unique, false if duplicate, nil if error
    private func isClassroomUniqueForCreator(
        userId: String,
        newName: String,
        currentClassroomId: String?,
        completion: @escaping (Bool?) -> Void
    ) {
        print("🔍 Checking uniqueness of classroom name '\(newName)' for user: \(userId)")

        let db = Firestore.firestore()
        
        // Find all classrooms where this user is the creator
        db.collectionGroup("members")
            .whereField("userId", isEqualTo: userId)
            .whereField("isCreator", isEqualTo: true)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Error querying user's classrooms: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let docs = snapshot?.documents else {
                    print("❌ No documents returned from query")
                    completion(nil)
                    return
                }
                
                print("📚 Found \(docs.count) classrooms created by this user")

                let syncQueue = DispatchQueue(label: "isUnique.sync")
                let dispatchGroup = DispatchGroup()
                
                var isUnique = true
                let cleanedNewName = newName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
                
                // Check each classroom this user created
                for doc in docs {
                    
                    guard isUnique else { break } // Short-circuit if duplicate found
                    
                    guard let classroomRef = doc.reference.parent.parent else {
                        continue
                    }
                    
                    dispatchGroup.enter()
                    
                    // Get the classroom document to check its name
                    classroomRef.getDocument { classroomDoc, error in
                        
                        if let classroomDoc = classroomDoc,
                           ((currentClassroomId == nil) || (classroomDoc.documentID != currentClassroomId)),
                           let name = classroomDoc.get("classroomName") as? String {
                            
                            if name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ==
                                cleanedNewName {
                                
                                print("❌ Found duplicate classroom name: '\(name)'")
                                
                                syncQueue.sync {
                                    isUnique = false
                                }
                            }
                        }
                        
                        dispatchGroup.leave()
                    }
                }
                
                // Wait for all checks to complete
                dispatchGroup.notify(queue: .main) {
                    completion(isUnique)
                }
            }
    }
    
    /// Validates that classroom name meets length requirements
    /// Classroom names must be between 8-150 characters
    /// - Parameter name: The classroom name to validate
    /// - Returns: True if valid length, false otherwise
    private func validateLengthOfClassroomName(name: String) -> Bool {
        let count = name.count
        
        guard !name.isEmpty, count >= 8, count <= 150 else {
            print("⚠️ Invalid classroom name length")
            return false
        }
        
        print("✅ Valid classroom name length")
        return true
    }
    
    /// Generates a new password for a classroom, invalidating the old one
    /// Used when teachers want to reset classroom access or if password is compromised
    /// - Parameters:
    ///   - documentId: The ID of the classroom
    ///   - completionHandler: Callback with new password if successful, nil if failed
    func regenerateClassroomPassword(
        documentId: String,
        completionHandler: @escaping (_: String?) -> Void
    ) {
        print("🔑 Regenerating password for classroom: \(documentId)")

        let newPassword = UUID().uuidString
        let passwordData = ["password": newPassword]
        
        let docRef = Firestore
            .firestore()
            .collection("classrooms")
            .document(documentId)
        
        docRef.updateData(passwordData) { error in
            
            if let error = error {
                
                print("❌ Error regenerating password: \(error.localizedDescription)")
                completionHandler(nil)
                
            } else {
                
                print("✅ Successfully generated new password: \(newPassword)")
                completionHandler(newPassword)
            }
        }
    }
    
    // MARK: - Quiz CRUD Operations
    
    /// Creates a new quiz within a classroom with questions and deadline
    /// Validates quiz name uniqueness within the classroom and creates all necessary documents
    /// - Parameters:
    ///   - classroomId: The ID of the classroom containing the quiz
    ///   - quizName: The name/title of the quiz
    ///   - deadline: When the quiz closes for submissions
    ///   - questions: Array of quiz questions with options and correct answers
    ///   - completionHandler: Callback - true: success, false: name conflict/invalid, nil: error
    func createQuiz(
        classroomId: String,
        quizName: String,
        deadline: Date,
        questions: [LocalQuestion],
        completionHandler: @escaping (_: Bool?) -> Void
    ) {
        print("📝 Creating quiz '\(quizName)' in classroom \(classroomId)")
        print("📅 Quiz deadline: \(deadline)")
        print("❓ Number of questions: \(questions.count)")
        
        let cleanedQuizName = self.cleanName(withName: quizName)
        
        let nameCount = cleanedQuizName.count
        let isValid = (nameCount >= 4 && nameCount <= 60)
        
        guard isValid else {
            print("❌ Quiz name validation failed: '\(cleanedQuizName)' (\(nameCount) chars)")
            completionHandler(false)
            return
        }
        
        // Check if quiz name is unique within this classroom
        self.isQuizNameUniqueForClassroom(
            quizName: cleanedQuizName,
            currentQuizId: nil,
            classroomId: classroomId,
            completion: { isUnique in
                
                guard let isUnique = isUnique else {
                    print("❌ Error checking quiz name uniqueness")
                    completionHandler(nil)
                    return
                }
                
                guard isUnique else {
                    print("❌ Quiz name '\(cleanedQuizName)' already exists in this classroom")
                    completionHandler(false)
                    return
                }
                
                // Create the quiz document
                let quizRef = Firestore
                    .firestore()
                    .collection("classrooms")
                    .document(classroomId)
                    .collection("quizzes")
                    .document()
                
                print("📝 Creating quiz document with ID: \(quizRef.documentID)")

                quizRef.setData([
                    "quizName": cleanedQuizName,
                    "createdAt": FieldValue.serverTimestamp(),
                    "deadline": deadline
                ]) { error in
                    
                    if let error = error {
                        print("❌ Error creating quiz document: \(error.localizedDescription)")
                        completionHandler(nil)
                        return
                    }
                    
                    print("✅ Quiz document created, now adding questions...")

                    // Use batch write to add all questions atomically
                    let batch = Firestore.firestore().batch()
                    
                    for q in questions {
                        let qRef = quizRef.collection("quizQuestions").document()
                        batch.setData(q.firestoreData, forDocument: qRef)
                    }
                    
                    // Commit all questions at once
                    batch.commit { err in
                        
                        if let err = err {
                            print("❌ Error creating quiz questions: \(err.localizedDescription)")
                            completionHandler(nil)
                            
                        } else {
                            
                            print("✅ Successfully created quiz '\(cleanedQuizName)' with \(questions.count) questions")
                            completionHandler(true)
                        }
                    }
                }
            }
        )
    }
    
    /// Retrieves all quizzes from a classroom with sorting options
    /// Used to display quiz lists to both teachers and students
    /// - Parameters:
    ///   - classroomId: The ID of the classroom
    ///   - isDescending: Whether to sort newest-first (true) or oldest-first (false)
    ///   - sortByDeadline: Whether to sort by deadline (true) or creation date (false)
    ///   - completionHandler: Callback with array of quizzes or nil if error
    func getAllQuizDocuments(
        classroomId: String,
        isDescending: Bool,
        sortByDeadline: Bool,
        completionHandler: @escaping ([Quiz]?) -> Void
    ) {
        print("📚 Fetching all quizzes for classroom: \(classroomId)")
        print("🔄 Sort by: \(sortByDeadline ? "deadline" : "creation date") (\(isDescending ? "descending" : "ascending"))")

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
                
                print("✅ Successfully retrieved \(quizData.count) quizzes")
                completionHandler(quizData)
                
            } catch {
                
                print("❌ Error fetching quizzes: \(error.localizedDescription)")
                completionHandler(nil)
            }
        }
    }
    
    /// Retrieves quiz statistics for all students in a classroom (admin view)
    /// Used by teachers to see how all students performed on a quiz
    /// - Parameters:
    ///   - classroomId: The ID of the classroom
    ///   - quizId: The ID of the specific quiz
    ///   - isDescending: Whether to sort by most recent attempts first
    ///   - completionHandler: Callback with array of quiz statistics or nil if error
    func getAllQuizStatsForAdmin(
        classroomId: String,
        quizId: String,
        isDescending: Bool,
        completionHandler: @escaping ([QuizStat]?) -> Void
    ) {
        print("📊 Fetching quiz stats for admin view - Quiz: \(quizId) in Classroom: \(classroomId)")

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
                
                print("✅ Successfully retrieved stats for \(stats.count) students")
                completionHandler(stats)
                
            } catch {
                
                print("❌ Error fetching quiz stats: \(error.localizedDescription)")
                completionHandler(nil)
            }
        }
    }
    
    /// Retrieves quiz statistics for a specific user (student view)
    /// Used by students to see their own performance and by teachers to view individual progress
    /// - Parameters:
    ///   - classroomId: The ID of the classroom
    ///   - quizId: The ID of the specific quiz
    ///   - userId: The ID of the user whose stats to retrieve
    ///   - completionHandler: Callback with QuizStat if found, nil if no attempts, or nil if error
    func getQuizStatsForUser(
        classroomId: String,
        quizId: String,
        userId: String,
        completionHandler: @escaping (QuizStat??) -> Void
    ) {
        print("📊 Fetching quiz stats for user: \(userId) - Quiz: \(quizId)")

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
                
                // User has never taken this quiz
                guard snapshot.exists else {
                    print("📊 No stats found for user \(userId) - first time taking quiz")
                    completionHandler(.some(nil))
                    return
                }
                
                let stat = try snapshot.data(as: QuizStat.self)
                
                print("✅ Found user stats: \(stat.attempts.count) attempts, last: \(stat.lastAttemptDate.formatted())")
                completionHandler(.some(stat))
                
            } catch {
                
                print("❌ Error fetching user quiz stats: \(error.localizedDescription)")
                completionHandler(nil)
            }
        }
    }
    
    /// Updates quiz name and deadline after validating constraints
    /// Used by teachers to modify quiz details before or after publication
    /// - Parameters:
    ///   - classroomId: The ID of the classroom
    ///   - quizId: The ID of the quiz to update
    ///   - quizName: The new name for the quiz
    ///   - deadline: The new deadline for the quiz
    ///   - createdAt: The original creation date (deadline must be after this)
    ///   - completionHandler: Callback with updated name if successful, nil if failed
    func updateQuizNameDeadline(
        classroomId: String,
        quizId: String,
        quizName: String,
        deadline: Date,
        createdAt: Date,
        completionHandler: @escaping (_: String?) -> Void
    ) {
        print("✏️ Updating quiz \(quizId): name='\(quizName)', deadline=\(deadline.formatted())")

        let cleanedQuizName = self.cleanName(withName: quizName)
        
        let nameCount = cleanedQuizName.count
        let isValid = (nameCount >= 4 && nameCount <= 60) && (deadline > createdAt)

        guard isValid else {
            print("❌ Quiz update validation failed: name length=\(nameCount), deadline after creation=\(deadline > createdAt)")
            completionHandler(nil)
            return
        }
        
        // Check if new name is unique within the classroom
        self.isQuizNameUniqueForClassroom(
            quizName: quizName,
            currentQuizId: quizId,
            classroomId: classroomId,
            completion: { isUnique in
                
                guard let isUnique = isUnique else {
                    print("❌ Error checking quiz name uniqueness")
                    completionHandler(nil)
                    return
                }
                
                guard isUnique else {
                    print("❌ Quiz name '\(cleanedQuizName)' already exists in this classroom")
                    completionHandler(nil)
                    return
                }
                
                // Update the quiz document
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
                    
                    if let error = error {
                        
                        print("❌ Error updating quiz: \(error.localizedDescription)")
                        completionHandler(nil)
                        
                    } else {
                        
                        print("✅ Successfully updated quiz to: '\(cleanedQuizName)'")
                        completionHandler(cleanedQuizName)
                    }
                }
            }
        )
    }
    
    /// Deletes a quiz and all associated data (questions and student statistics)
    /// This is a destructive operation that cannot be undone
    /// - Parameters:
    ///   - classroomId: The ID of the classroom
    ///   - quizId: The ID of the quiz to delete
    ///   - completionHandler: Callback indicating success/failure
    func deleteQuiz(
        classroomId: String,
        quizId: String,
        completionHandler: @escaping (Bool) -> Void
    ) {
        print("🗑️ Deleting quiz: \(quizId) from classroom: \(classroomId)")

        let db = Firestore.firestore()
        
        let quizRef = db
            .collection("classrooms")
            .document(classroomId)
            .collection("quizzes")
            .document(quizId)
        
        Task {
            do {
        
                // Delete quiz questions subcollection
                let questionsSnapshot = try await quizRef.collection("quizQuestions").getDocuments()
                print("🗑️ Deleting \(questionsSnapshot.documents.count) quiz questions")

                for doc in questionsSnapshot.documents {
                    try await doc.reference.delete()
                }
                
                // Delete quiz statistics subcollection (all student attempts)
                let statsSnapshot = try await quizRef.collection("stats").getDocuments()
                print("🗑️ Deleting stats for \(statsSnapshot.documents.count) students")

                for doc in statsSnapshot.documents {
                    try await doc.reference.delete()
                }
                
                // Delete the quiz document itself
                try await quizRef.delete()
                print("✅ Successfully deleted quiz and all associated data")
                
                completionHandler(true)
                
            } catch {
                
                print("❌ Error deleting quiz: \(error.localizedDescription)")
                completionHandler(false)
            }
        }
    }
    
    /// Retrieves all questions for a specific quiz
    /// Used when students take a quiz or teachers review quiz content
    /// - Parameters:
    ///   - classroomId: The ID of the classroom
    ///   - quizId: The ID of the quiz
    ///   - completionHandler: Callback with array of questions or nil if error
    func getAllQuestionsFromQuiz(
        classroomId: String,
        quizId: String,
        completionHandler: @escaping ([Question]?) -> Void
    ) {
        print("❓ Fetching all questions for quiz: \(quizId)")

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
                
                print("✅ Successfully retrieved \(questions.count) questions")
                completionHandler(questions)
                
            } catch {
                
                print("❌ Error fetching quiz questions: \(error.localizedDescription)")
                completionHandler(nil)
            }
        }
    }
    
    /// Submits or updates a student's quiz attempt and statistics
    /// Creates new stats record if first attempt, or appends to existing attempts
    /// - Parameters:
    ///   - userId: The ID of the student taking the quiz
    ///   - classroomId: The ID of the classroom
    ///   - quizId: The ID of the quiz
    ///   - newAttempt: The attempt data (score, timestamp, etc.)
    ///   - completionHandler: Callback with success status or nil if error
    func submitStatsForQuiz(
        userId: String,
        classroomId: String,
        quizId: String,
        newAttempt: Attempt,
        completionHandler: @escaping (Bool?) -> Void
    ) {
        print("📊 Submitting quiz stats for user: \(userId)")
        print("🎯 Score: \(newAttempt.score)/\(newAttempt.totalScore) at \(newAttempt.attemptDate.formatted())")

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
                
                // Get user information for the stats record
                guard let user = await self.getUser(userId: userId) else {
                    print("❌ Could not retrieve user data for stats submission")
                    completionHandler(nil)
                    return
                }

                // Check if user has existing stats for this quiz
                let snapshot = try await statsRef.getDocument()

                var stat: QuizStat

                if snapshot.exists, let existing = try? snapshot.data(as: QuizStat.self) {
                    
                    print("📊 Found existing stats with \(existing.attempts.count) previous attempts")
                    
                    // Append new attempt to existing attempts
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
                    print("📊 Creating new stats record - first attempt")
                    
                    // Create new stats record with first attempt
                    stat = QuizStat(
                        id: userId,
                        userId: user.userId,
                        email: user.email,
                        name: user.name,
                        lastAttemptDate: newAttempt.attemptDate,
                        attempts: [newAttempt]
                    )
                }

                // Save the updated stats to Firestore
                try statsRef.setData(from: stat, merge: true)
                print("✅ Successfully submitted quiz stats")

                completionHandler(true)

            } catch {
                
                print("❌ Failed to submit quiz stats: \(error.localizedDescription)")
                completionHandler(false)
            }
        }
    }

    /// Checks if a quiz name is unique within a specific classroom
    /// Quiz names must be unique within each classroom but can be duplicate across classrooms
    /// - Parameters:
    ///   - quizName: The proposed quiz name
    ///   - currentQuizId: ID of quiz being edited (excluded from uniqueness check)
    ///   - classroomId: The ID of the classroom
    ///   - completion: Callback with true if unique, false if duplicate, nil if error
    private func isQuizNameUniqueForClassroom(
        quizName: String,
        currentQuizId: String?,
        classroomId: String,
        completion: @escaping (Bool?) -> Void
    ) {
        print("🔍 Checking uniqueness of quiz name '\(quizName)' in classroom: \(classroomId)")

        let db = Firestore.firestore()

        db.collection("classrooms")
            .document(classroomId)
            .collection("quizzes")
            .getDocuments { snapshot, error in
                
                if let error = error {
                    print("❌ Error querying classroom quizzes: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let docs = snapshot?.documents else {
                    print("❌ No documents returned from quiz query")
                    completion(nil)
                    return
                }

                let cleanedQuizName = quizName
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                    .lowercased()
                
                print("📚 Checking against \(docs.count) existing quizzes")

                // Check each existing quiz for name conflicts
                for doc in docs {
                    guard let quizData = try? doc.data(as: Quiz.self),
                          let quizId = quizData.id else { continue }

                    // Skip the current quiz if we're editing
                    if quizId != currentQuizId &&
                        cleanedQuizName == quizData.quizName
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                            .lowercased() {
                        
                        print("❌ Found duplicate quiz name: '\(quizData.quizName)'")
                        completion(false)
                        return
                    }
                }

                print("✅ Quiz name is unique within classroom")
                completion(true)
            }
    }

    // MARK: - Utility Methods

    /// Cleans and normalizes text input by removing extra whitespace
    /// Used for classroom names, quiz names, and other user input
    /// - Parameter withName: The raw text input
    /// - Returns: Cleaned text with normalized spacing
    private func cleanName(withName: String) -> String {
        
        // Remove leading/trailing whitespace
        let trimmedName = withName
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Split by whitespace and filter out empty components
        let components = trimmedName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        // Rejoin with single spaces
        return components.joined(separator: " ")
    }
}
