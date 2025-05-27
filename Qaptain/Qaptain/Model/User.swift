//
//  User.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/27/25.
//

import FirebaseFirestore

struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var email: String
    var name: String
}
