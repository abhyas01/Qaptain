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

    @EnvironmentObject var authController: AuthController
    
    // MARK: - State Properties

    @State private var email = ""
    @State private var password = ""
    @State private var retryPassword = ""
    @State private var fullName = ""
    
    // MARK: - Body

    var body: some View {
        VStack {
            Form {
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
                
                if authController.isSignUp && !authController.hasForgotPassword {
                    Section("Full Name") {
                        TextField("Full Name",
                                  text: $fullName
                        )
                        .font(.title2)
                    }
                }
                
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
                
                if !authController.hasForgotPassword {
                    Section("Password") {
                        SecureField("Password", text: $password)
                            .font(.title2)
                    }
                    
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
                dismissKeyboard()
            }

            VStack(spacing: 8) {
                Button {
                    if authController.hasForgotPassword {
                        authController.forgotPasswortEmailSend(
                            email: email
                        )
                    } else {
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
                            Text("Loading")
                            ProgressView()
                        } else {
                            Text(authController.submitButtonText)
                                .font(.title2)
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(authController.isLoading)
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)

                if !authController.hasForgotPassword {
                    Button(authController.buttonTextToToggle) {
                        authController.toggleSignUp()
                    }
                    .disabled(authController.isLoading)
                    .padding(.top)
                }
                
                if !authController.isSignUp {
                    Button(authController.forgotPasswordText) {
                        authController.toggleForgotPassword()
                    }
                    .disabled(authController.isLoading)
                    .padding(.top)
                }

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
