//
//  AuthController.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/4/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseFirestore

// MARK: - Authentication State Enum

/// Represents the current authentication state of the user
enum AuthState {
    case undefined, authenticated, unauthenticated
}

// MARK: - Authentication Controller

/// Singleton class that handles Firebase Auth integration
class AuthController: ObservableObject {
    
    // MARK: - Singleton

    /// Shared singleton instance ensures only one AuthController exists throughout app lifecycle
    static let shared = AuthController()
    
    // MARK: - Published Properties

    /// Current authentication state that triggers UI updates when changed
    /// Views observe this property to determine whether to show login screen or authenticated content
    @Published var authStatus: AuthState = .undefined
    
    /// Controls whether the UI displays sign up form (true) or sign in form (false)
    /// Toggles between creating new account vs logging into existing account
    @Published var isSignUp = false
    
    /// Loading state for authentication operations to show progress indicators
    /// Prevents multiple simultaneous auth requests and provides user feedback
    @Published var isLoading = false
    
    /// Controls forgot password mode - when true, shows password reset UI instead of login form
    /// Allows users to recover access to their accounts via email reset
    @Published var hasForgotPassword = false
    
    /// Tracks whether password reset email was successfully sent
    /// Used to show confirmation message and update UI accordingly
    @Published var didSentResetEmail = false
    
    /// Error message to display to user when authentication operations fail
    /// Provides specific feedback about what went wrong during auth attempts
    @Published var errorMessage: String? = nil
    
    // MARK: - Properties
    
    /// Current user's unique Firebase Auth ID, used for database operations and user identification
    /// Empty string when no user is authenticated, populated when user signs in successfully
    var userId: String = ""
    
    /// Current user's email address from Firebase Auth
    /// Used for display purposes and account management operations
    var email: String?
    
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

    private init() { }

    // MARK: - Authentication Methods

    /// Main authentication method that handles both sign in and sign up operations
    /// Validates user input, cleans data, and routes to appropriate Firebase Auth method
    /// - Parameters:
    ///   - email: User's email address for authentication
    ///   - password: User's password for authentication
    ///   - retryPassword: Password confirmation for sign up (must match password)
    ///   - fullName: User's full name for account creation (required for sign up only)
    func authenticate(email: String, password: String, retryPassword: String, fullName: String) {
        print("🔐 Starting authentication process - isSignUp: \(self.isSignUp)")
        print("📧 Authentication attempt for email: \(email)")
        
        Task {
            
            // Reset UI state and show loading indicator
            self.resetUIBeforeAuthentication()
            
            // Clean and validate input
            let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedRetryPassword = retryPassword.trimmingCharacters(in: .whitespacesAndNewlines)
            let cleanedFullName = self.cleanAndCapitalizeFullName(fullName)
            
            print("✂️ Cleaned email: '\(trimmedEmail)'")
            print("✂️ Cleaned full name: '\(cleanedFullName)' (length: \(cleanedFullName.count))")
            
            // Validate email is not empty - required for both sign in and sign up
            guard !trimmedEmail.isEmpty else {
                print("❌ Validation failed: Email is empty")
                self.authenticateWithFailure(message: "Email can't be empty.")
                return
            }
            
            // Validate full name for sign up only - not required for sign in
            guard !cleanedFullName.isEmpty || !self.isSignUp else {
                print("❌ Validation failed: Full name is empty for sign up")
                self.authenticateWithFailure(message: "Full Name can't be empty.")
                return
            }
            
            // Validate full name length for sign up - must be reasonable length for database storage
            guard cleanedFullName.count >= 7 && cleanedFullName.count <= 20 || !self.isSignUp else {
                print("❌ Validation failed: Full name length (\(cleanedFullName.count)) not between 7-20 characters")
                self.authenticateWithFailure(message: "Full Name must be between 7 and 20 characters long.")
                return
            }
            
            // For sign up, ensure passwords match to prevent account creation with mistyped password
            guard trimmedPassword == trimmedRetryPassword || !self.isSignUp else {
                print("❌ Validation failed: Passwords do not match for sign up")
                self.authenticateWithFailure(message: "Passwords do not match.")
                return
            }
            
            // Validate password is not empty - required for both sign in and sign up
            guard !trimmedPassword.isEmpty else {
                print("❌ Validation failed: Password is empty")
                self.authenticateWithFailure(message: "Password can't be empty.")
                return
            }
            
            // Route to appropriate authentication method based on current mode
            if self.isSignUp {
                print("🆕 Routing to sign up with email: \(trimmedEmail), name: \(cleanedFullName)")
                await self.signUp(email: trimmedEmail, password: trimmedPassword, withFullName: cleanedFullName)
            } else {
                print("🔑 Routing to sign in with email: \(trimmedEmail)")
                await self.signIn(email: trimmedEmail, password: trimmedPassword)
            }
        }
    }
    
    /// Sends password reset email to the specified email address
    /// Allows users to recover access to their accounts when they forget their password
    /// - Parameter email: Email address to send reset instructions to
    func forgotPasswortEmailSend(email: String) {
        print("📧 Initiating password reset for email: \(email)")

        // Reset UI state before attempting to send email
        self.resetUIBeforeAuthentication()
        
        // Use Firebase Auth to send password reset email
        Auth.auth().sendPasswordReset(withEmail: email) { [weak self] error in
            if let error = error {
                
                print("❌ Password reset failed: \(error.localizedDescription)")
                self?.authenticateWithFailure(message: error.localizedDescription)
                
            } else {
                
                print("✅ Password reset email sent successfully to: \(email)")
                self?.authenticateWithSuccess()
                self?.sentEmailUIState()
            }
        }
    }
    
    /// Sets up Firebase Auth state listener to monitor authentication changes
    /// Automatically updates app state when user signs in, signs out, or session expires
    func listenToAuthChanges() {
        print("👂 Setting up Firebase Auth state change listener")

        let _ = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            
            print("🔄 Auth state change detected")

            // Update UI on main thread with smooth animation
            DispatchQueue.main.async {
                withAnimation {
                    self?.authStatus = user != nil ? .authenticated : .unauthenticated
                }
            }
            
            // Store or clear user information based on authentication status
            if let user = Auth.auth().currentUser {
                self?.userId = user.uid
                self?.email = user.email
                
                print("👤 User authenticated - ID: \(user.uid)")
                print("📧 User email: \(user.email ?? "No email")")
                print("✅ User data stored in AuthController")
            } else {
                
                print("❌ No user is signed in - clearing stored user data")
            }
        }
    }
    
    /// Signs out the current user and clears local authentication data
    /// Returns user to login screen and removes all cached user information
    func signout() {
        print("🚪 Initiating user sign out")

        do {
            try Auth.auth().signOut()
            print("✅ User signed out successfully")

        } catch {
            print("❌ Sign out failed: \(error.localizedDescription)")

        }
    }
    
    // MARK: - UI State Management

    /// Toggles between sign in and sign up modes with smooth animation
    /// Clears any existing error messages when switching modes
    func toggleSignUp() {
        DispatchQueue.main.async {
            withAnimation {
                self.isSignUp.toggle()
                self.errorMessage = nil
            }
        }
    }
    
    /// Toggles forgot password mode on/off with appropriate state management
    /// Handles entering and exiting password reset workflow
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

    /// Creates a new user account with Firebase Auth and stores user data in Firestore
    /// Handles the complete sign up process including database user record creation
    /// - Parameters:
    ///   - email: User's email address for account creation
    ///   - password: User's chosen password for account security
    ///   - name: User's full name for profile and identification
    private func signUp(email: String, password: String, withFullName name: String) async {
        print("🆕 Starting Firebase sign up process")
        print("📧 Creating account for email: \(email)")
        print("👤 User name: \(name)")
        
        do {
            
            // Create Firebase Auth account
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let user = result.user
            
            print("✅ Firebase Auth account created successfully")
            print("🆔 New user ID: \(user.uid)")
            
            // Prepare user data for Firestore database
            let userData: [String: String] = [
                "userId": user.uid,
                "email": user.email ?? email,
                "name": name
            ]
            
            print("💾 Creating Firestore user document with data: \(userData)")
            
            // Store user information in Firestore users collection
            try await Firestore.firestore().collection("users").document(user.uid).setData(userData)
            
            print("✅ User document created successfully in Firestore")
            print("🎉 Sign up process completed successfully")
            
            self.authenticateWithSuccess()
            
        } catch {
            
            print("❌ Sign up failed: \(error.localizedDescription)")
            self.authenticateWithFailure(message: error.localizedDescription)
        }
    }
    
    /// Signs in existing user with Firebase Auth credentials
    /// Validates credentials against Firebase Auth and establishes user session
    /// - Parameters:
    ///   - email: User's registered email address
    ///   - password: User's account password
    private func signIn(email: String, password: String) async {
        print("🔑 Starting Firebase sign in process")
        print("📧 Signing in user with email: \(email)")
        
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            
            print("✅ Sign in successful")
            print("🎉 User authenticated and session established")
            
            self.authenticateWithSuccess()
            
        } catch {
            
            print("❌ Sign in failed: \(error.localizedDescription)")
            self.authenticateWithFailure(message: error.localizedDescription)
        }
    }

    /// Cleans and properly capitalizes user's full name for consistent formatting
    /// Removes extra whitespace and capitalizes each word for professional appearance
    /// - Parameter fullName: Raw full name input from user
    /// - Returns: Cleaned and properly formatted full name
    private func cleanAndCapitalizeFullName(_ fullName: String) -> String {
        
        // Remove leading and trailing whitespace
        let trimmedFullName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Split by whitespace and remove empty components
        let components = trimmedFullName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        // Capitalize each word properly (first letter uppercase, rest lowercase)
        let capitalizedComponents = components.map { word in
            word.prefix(1).uppercased() + word.dropFirst().lowercased()
        }
        
        return capitalizedComponents.joined(separator: " ")
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
