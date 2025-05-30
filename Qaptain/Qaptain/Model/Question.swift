//
//  Question.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/29/25.
//

import FirebaseFirestore

struct Question: Identifiable, Codable {
    @DocumentID var id: String?
    var question: String
    var options: [String]
    var answer: String
    
    // Local UI-only property
    var tappedAnswer: String = ""
    
    enum CodingKeys: String, CodingKey {
        case id
        case question
        case options
        case answer
    }
}
