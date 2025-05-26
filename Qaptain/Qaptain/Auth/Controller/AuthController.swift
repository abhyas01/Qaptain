//
//  AuthController.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/4/25.
//

import SwiftUI
import FirebaseAuth

// MARK: - Authentication State Enum

/// Represents the current authentication state of the user
enum AuthState {
    case undefined, authenticated, unauthenticated
}

// MARK: - Authentication Controller

/// Singleton class that handles Firebase Auth integration
class AuthController: ObservableObject {
    
    // MARK: - Singleton

    static let shared = AuthController()
    
    // MARK: - Published Properties

    @Published var authStatus: AuthState = .undefined
    @Published var isSignUp = false
    @Published var isLoading = false
    @Published var hasForgotPassword = false
    @Published var didSentResetEmail = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Properties

    var userId: String = ""
    
    // MARK: - Computed Properties

    /// Dynamic text for toggle button between sign in and sign up
    var buttonTextToToggle: String {
        self.isSignUp ? "I have an account? SignIn" : "New User? SignUp"
    }
    
    /// Dynamic text for forgot password functionality
    var forgotPasswordText: String {
        self.hasForgotPassword ? "I am ready to SignIn" : "Forgot Password?"
    }
    
    /// Dynamic text for submit button based on current state
    var submitButtonText: String {
        if self.hasForgotPassword {
            return self.didSentResetEmail ? "Send Reset Email Again" : "Send Reset Email"
        } else {
            return self.isSignUp ? "SignUp" : "SignIn"
        }
    }
    
    /// Feedback text for forgot password functionality
    var forgotPasswordFeedbackText: String {
        return self.didSentResetEmail ? "Email Sent" : "You will get an email at this address to reset your password."
    }
    
    // MARK: - Initialization

    private init() {
        listenToAuthChanges() // FIXME: - REMOVE ME I ONLY EXIST FOR TESTING PURPOSES
    }

    // MARK: - Authentication Methods

    /// Main authentication method that handles both sign in and sign up
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    ///   - retryPassword: Password confirmation for sign up
    func authenticate(email: String, password: String, retryPassword: String) {
        Task {
            self.resetUIBeforeAuthentication()
            
            // Clean and validate input
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedRetryPassword = retryPassword.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Validate email is not empty
            guard !trimmedEmail.isEmpty else {
                self.authenticateWithFailure(message: "Email can't be empty.")
                return
            }
            
            // For sign up, ensure passwords match
            guard trimmedPassword == trimmedRetryPassword || !self.isSignUp else {
                self.authenticateWithFailure(message: "Passwords do not match.")
                return
            }
            
            // Validate password is not empty
            guard !trimmedPassword.isEmpty else {
                self.authenticateWithFailure(message: "Password can't be empty.")
                return
            }
            
            // Route to appropriate authentication method
            if self.isSignUp {
                await self.signUp(email: email, password: password)
            } else {
                await self.signIn(email: email, password: password)
            }
        }
    }
    
    /// Sends password reset email to the specified email address
    /// - Parameter email: Email address to send reset instructions to
    func forgotPasswortEmailSend(email: String) {
        self.resetUIBeforeAuthentication()
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            if let error = error {
                self?.authenticateWithFailure(message: error.localizedDescription)
            } else {
                self?.authenticateWithSuccess()
                self?.sentEmailUIState()
            }
        }
    }
    
    /// Sets up Firebase Auth state listener to monitor authentication changes
    func listenToAuthChanges() {
        let _ = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            
            // Update UI on main thread with animation
            DispatchQueue.main.async {
                withAnimation {
                    self?.authStatus = user != nil ? .authenticated : .unauthenticated
                }
            }
            
            // Store or clear user ID based on authentication status
            if let user = Auth.auth().currentUser {
                self?.userId = user.uid
                print("User ID: \(String(describing: self?.userId))")
            } else {
                print("No user is signed in,")
            }
        }
    }
    
    /// Signs out the current user and clears local data
    func signout() {
        do {
            try Auth.auth().signOut()
        } catch {
            print(String(describing: error.localizedDescription))
        }
    }
    
    // MARK: - UI State Management

    /// Toggles between sign in and sign up modes
    func toggleSignUp() {
        DispatchQueue.main.async {
            withAnimation {
                self.isSignUp.toggle()
                self.errorMessage = nil
            }
        }
    }
    
    /// Toggles forgot password mode on/off
    func toggleForgotPassword() {
        DispatchQueue.main.async {
            withAnimation {
                if self.hasForgotPassword {
                    
                    // Reset forgot password state
                    self.hasForgotPassword = false
                    self.errorMessage = nil
                    self.didSentResetEmail = false
                } else {
                    
                    // Enter forgot password mode
                    self.hasForgotPassword = true
                    self.errorMessage = nil
                }
            }
        }
    }
    
    // MARK: - Private Authentication Methods

    /// Creates a new user account with Firebase Auth
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's chosen password
    private func signUp(email: String, password: String) async {
        do {
            try await Auth.auth().createUser(withEmail: email, password: password)
            self.authenticateWithSuccess()
        } catch {
            self.authenticateWithFailure(message: error.localizedDescription)
        }
    }
    
    /// Signs in existing user with Firebase Auth
    /// - Parameters:
    ///   - email: User's email address
    ///   - password: User's password
    private func signIn(email: String, password: String) async {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            self.authenticateWithSuccess()
        } catch {
            self.authenticateWithFailure(message: error.localizedDescription)
        }
    }

    // MARK: - Private UI Helper Methods

    /// Resets UI state before starting authentication process
    private func resetUIBeforeAuthentication() {
        DispatchQueue.main.async {
            withAnimation {
                self.isLoading = true
                self.errorMessage = nil
            }
        }
    }
    
    /// Updates UI state after successful authentication
    private func authenticateWithSuccess() {
        DispatchQueue.main.async {
            withAnimation {
                self.isLoading = false
                self.errorMessage = nil
            }
        }
    }
    
    /// Updates UI state after authentication failure
    /// - Parameter message: Error message to display to user
    private func authenticateWithFailure(message: String) {
        DispatchQueue.main.async {
            withAnimation {
                self.isLoading = false
                self.errorMessage = message
            }
        }
    }
    
    /// Updates UI state after password reset email is sent
    private func sentEmailUIState() {
        DispatchQueue.main.async {
            withAnimation {
                self.didSentResetEmail = true
                self.errorMessage = nil
            }
        }
    }
}
