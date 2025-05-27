//
//  Member.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/27/25.
//

import FirebaseFirestore

struct Member: Identifiable, Codable {
    @DocumentID var id: String?
    var classroomName: String
    @ServerTimestamp var createdAt: Date?
    var createdByName: String
    var password: String
}
