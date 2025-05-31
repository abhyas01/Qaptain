//
//  User.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/27/25.
//

import FirebaseFirestore

/// Represents a user account in the Qaptain application with Firebase integration
/// Core model for user authentication, profile management, and account identification
/// Links Firebase Auth accounts to application data and classroom memberships
/// Used throughout the app for user identification, profile display, and access control
struct User: Identifiable, Codable {
    @DocumentID var id: String?
    var userId: String
    var email: String
    var name: String
}
