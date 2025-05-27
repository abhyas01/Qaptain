//
//  EnrollClassroomSheet.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/27/25.
//

import SwiftUI

struct EnrollClassroomSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let userId: String
    var onSuccessfulEnrollment: (() -> Void)? = nil
    
    @State private var password: String = ""
    @State private var isJoining: Bool = false
    @State private var errorMessage: String? = nil
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Classroom Password") {
                    TextField("Type Classroom Password", text: $password)
                }
                
                Button {
                    joinClassroom()
                } label: {
                    HStack {
                        Text("Join Classroom")
                        
                        if isJoining {
                            ProgressView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(isJoining)
                .buttonStyle(.borderedProminent)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
            }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Join Classroom")
                        .fontDesign(.rounded)
                        .foregroundStyle(.orange)
                        .fontWeight(.bold)
                }
                
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Cancel")
                    }
                }
                
                ToolbarItem(placement: .keyboard) {
                    HStack {
                        Spacer()
                        
                        Button {
                            dismissKeyboard()
                        } label: {
                            Image(
                                systemName: "keyboard.chevron.compact.down"
                            )
                            .tint(.orange)
                        }
                    }
                }
            }
        }
        .presentationDetents([.medium])
    }
    
    private func joinClassroom() {
        withAnimation {
            isJoining = true
            errorMessage = nil
        }
        
        DataManager.shared.joinClassroom(
            userId: userId,
            password: password,
            completionHandler: { success in
                DispatchQueue.main.async {
                    
                    withAnimation {
                        isJoining = false
                    }
                    
                    switch success {
                        
                    case true:
                        dismiss()
                        onSuccessfulEnrollment?()
                        
                    case false:
                        withAnimation {
                            errorMessage = "Invalid password or you're already enrolled in this class."
                        }
                        
                    case nil:
                        withAnimation {
                            errorMessage = "An unexpected error occurred. Try later?"
                        }
                        
                    case .some(_):
                        break
                    }
                }
            }
        )

    }
    
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

#Preview {
    EnrollClassroomSheet(userId: "3rNFDKJebENEfHqVFg475bJXb9j1")
}
