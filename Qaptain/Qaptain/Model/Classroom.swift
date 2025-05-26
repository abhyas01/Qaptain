//
//  Classroom.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/23/25.
//

import FirebaseFirestore

struct Classroom: Identifiable, Codable {
    @DocumentID var id: String?
    var classroomName: String
    var createdById: String
    var createdByName: String
    @ServerTimestamp var createdAt: Date?
}
