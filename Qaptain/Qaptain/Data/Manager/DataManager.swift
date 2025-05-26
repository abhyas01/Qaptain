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
    
    func fetchClassroomPassword(
        documentId: String,
        failedCompletionHandler: @escaping () -> Void,
        completionHandler: @escaping (_: String) -> Void
    ) {
        Firestore.firestore()
            .collection("classrooms")
            .document(documentId)
            .collection("secrets")
            .limit(to: 1)
            .getDocuments { snapshot, error in
                
                if let document = snapshot?.documents.first,
                   let password = document.data()["password"] as? String {
                    
                    DispatchQueue.main.async {
                        withAnimation {
                            completionHandler(password)
                        }
                    }
                    
                } else {
                    
                    DispatchQueue.main.async {
                        withAnimation {
                            failedCompletionHandler()
                        }
                    }
                }
            }
    }
    
    func regenerateClassroomPassword(
        documentId: String,
        completionHandler: @escaping (_: String?) -> Void
    ) {
        let newPassword = UUID().uuidString
        
        let passwordData = ["password": newPassword]
        
        Firestore
            .firestore()
            .collection("classrooms")
            .document(documentId)
            .collection("secrets")
            .limit(to: 1)
            .getDocuments { snapshot, error in
                
                if let doc = snapshot?.documents.first {
                    
                    doc.reference.updateData(passwordData) { error in
                        
                        DispatchQueue.main.async {
                            withAnimation {
                                completionHandler(error == nil ? newPassword : nil)
                            }
                        }
                    }
                    
                } else {
                    
                    DispatchQueue.main.async {
                        withAnimation {
                            completionHandler(nil)
                        }
                    }
                }
            }
    }
    
    func updateClassroomName(
        documentId: String,
        withName: String,
        completionHandler: @escaping (_: String?) -> Void
    ) {
//        let cleanedName = self.validateName(withName: withName)
        
        Firestore
            .firestore()
            .collection("classrooms")
            .document(documentId)
            .updateData(["classroomName": withName]) { error in
                
                DispatchQueue.main.async {
                    withAnimation {
                        completionHandler(error == nil ? withName : nil)
                    }
                }
            }
    }
    
//    private func validateName(
//        withName name: String
//    ) -> String {
//        
//    }
}
