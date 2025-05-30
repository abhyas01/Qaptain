//
//  Quiz.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/27/25.
//

import FirebaseFirestore

struct Quiz: Identifiable, Codable {
    @DocumentID var id: String?
    @ServerTimestamp var createdAt: Date?
    var deadline: Date
    var quizName: String
}
