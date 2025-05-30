//
//  QuizStat.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/28/25.
//

import FirebaseFirestore

struct QuizStat: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var email: String
    var name: String
    var lastAttemptDate: Date
    var attempts: [Attempt]
}
