//
//  AuthView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/23/25.
//

import SwiftUI
import UIKit

// MARK: - Authentication View

/// Main authentication screen that handles user sign in, sign up, and password reset
struct AuthView: View {
    
    // MARK: - Environment Objects

    /// Shared authentication controller that manages all auth state and Firebase operations
    /// Observed for real-time updates to authentication status, loading states, and error messages
    @EnvironmentObject var authController: AuthController
    
    // MARK: - State Properties

    /// User's email input - automatically converted to lowercase for consistency
    /// Binds to text field and passes to AuthController for authentication operations
    @State private var email = ""
    
    /// User's password input for authentication
    /// Secure field input that's passed to AuthController for sign in/sign up
    @State private var password = ""
    
    /// Password confirmation field for sign up validation
    /// Must match primary password field to prevent account creation errors
    @State private var retryPassword = ""
    
    /// User's full name for account creation during sign up process
    /// Required field for new user registration, creates user profile in database
    @State private var fullName = ""
    
    // MARK: - Body

    var body: some View {
        VStack {
            
            // Main form container with dynamic fields based on authentication mode
            Form {
                
                // Profile icon header section
                HStack {
                    Spacer()
                    Image(systemName: "person.circle.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 200)
                        .foregroundStyle(.orange)
                    Spacer()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                
                
                Spacer()
                    .listRowBackground(Color.clear)
                
                // Full name field - only shown during sign up and not in forgot password mode
                if authController.isSignUp && !authController.hasForgotPassword {
                    Section("Full Name") {
                        TextField("Full Name",
                                  text: $fullName
                        )
                        .font(.title2)
                    }
                }
                
                // Email field - always visible for all authentication operations
                Section("Email") {
                    TextField("Email",
                              text: Binding(
                                get: { email },
                                set: { email = $0.lowercased() }
                            )
                    )
                    .textInputAutocapitalization(.never)
                    .font(.title2)
                }
                
                // Password reset feedback - only shown in forgot password mode
                if authController.hasForgotPassword {
                    HStack {
                        Text(authController.forgotPasswordFeedbackText)
                            .multilineTextAlignment(.center)
                            .font(.footnote)
                            .foregroundStyle(
                                authController.didSentResetEmail ?
                                    .green :
                                        .secondary
                            )
                        
                        if authController.didSentResetEmail {
                            Image(systemName: "checkmark.circle")
                                .foregroundStyle(.green)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                }
                
                // Password fields - hidden in forgot password mode
                if !authController.hasForgotPassword {
                    Section("Password") {
                        SecureField("Password", text: $password)
                            .font(.title2)
                    }
                    
                    // Confirm password field - only shown during sign up
                    if authController.isSignUp {
                        Section("Rewrite Password") {
                            SecureField("Rewrite Password", text: $retryPassword)
                                .font(.title2)
                        }
                    }
                }
            }
            .padding(.bottom)
            .onTapGesture {
                
                // Dismiss keyboard when user taps outside form fields
                dismissKeyboard()
            }

            // Action buttons and error display section
            VStack(spacing: 8) {
                Button {
                    print("🎯 Submit button tapped - mode: \(authController.hasForgotPassword ? "forgot password" : (authController.isSignUp ? "sign up" : "sign in"))")

                    // Call forgot password function if forgot password
                    if authController.hasForgotPassword {
                        
                        print("📧 Sending password reset email to: \(email)")

                        authController.forgotPasswortEmailSend(
                            email: email
                        )
                        
                    } else {
                        
                        print("🔐 Authenticating user - email: \(email), isSignUp: \(authController.isSignUp)")

                        // Call authenticate function if SignUp or SignIn
                        authController.authenticate(
                            email: email,
                            password: password,
                            retryPassword: retryPassword,
                            fullName: fullName
                        )
                    }
                    
                } label: {
                    
                    HStack {
                        if authController.isLoading {
                            
                            // Loading Feedback
                            Text("Loading")
                            ProgressView()
                            
                        } else {
                            
                            // Submit button with dynamic text
                            Text(authController.submitButtonText)
                                .font(.title2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(authController.isLoading)
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                // SignUp/SignIn toggle button only visible if not in forgot password state
                if !authController.hasForgotPassword {
                    
                    // SignUp/SignIn toggle button with dynamic text
                    Button(authController.buttonTextToToggle) {
                        authController.toggleSignUp()
                    }
                    .disabled(authController.isLoading)
                    .padding(.top)
                }
                
                // Forgot Password toggle button - only visible in SignIn and Forgot Password mode (not SignUp mode)
                if !authController.isSignUp {
                    Button(authController.forgotPasswordText) {
                        authController.toggleForgotPassword()
                    }
                    .disabled(authController.isLoading)
                    .padding(.top)
                }

                // Error Feedback to the user
                if let errorMessage = authController.errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .font(.footnote)
                        .multilineTextAlignment(.center)
                        .padding(.top)
                }
            }
            .padding(.bottom)
        }
        .tint(.orange)
        .toolbar {
            
            // Button to dismiss the keyboard
            ToolbarItem(placement: .keyboard) {
                HStack {
                    Spacer()
                    Button {
                        dismissKeyboard()
                    } label: {
                        Image(systemName: "keyboard.chevron.compact.down")
                    }
                    .foregroundStyle(.orange)
                }
            }
        }
    }
    
    // MARK: - Helper Methods

    /// Dismisses the on-screen keyboard
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(
                UIResponder.resignFirstResponder
            ),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

// MARK: - Preview

#Preview {
    let authController = AuthController.shared
    AuthView()
        .environmentObject(authController)
}
