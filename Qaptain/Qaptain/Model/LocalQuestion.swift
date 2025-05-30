//
//  LocalQuestion.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/30/25.
//

import Foundation

struct LocalQuestion: Identifiable {
    let id = UUID()
    var prompt: String = ""
    var options: [String] = [""]
    var answer: String = ""

    var trimmedPrompt: String {
        return prompt.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var trimmedOptions: [String] {
        let trimmedOptions = options.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        return trimmedOptions.filter { !$0.isEmpty }
    }
    
    var trimmedAnswer: String {
        return answer.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var isValid: Bool {
        return !trimmedPrompt.isEmpty && !trimmedOptions.isEmpty && trimmedOptions.contains(trimmedAnswer)
    }

    var firestoreData: [String: Any] {
        [
            "question": trimmedPrompt,
            "options": trimmedOptions,
            "answer": trimmedAnswer
        ]
    }
}
