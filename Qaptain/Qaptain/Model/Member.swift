//
//  Member.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/27/25.
//

import FirebaseFirestore

struct Member: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var email: String
    var name: String
    var isCreator: Bool
    var classroomCreatedAt: Date
}
