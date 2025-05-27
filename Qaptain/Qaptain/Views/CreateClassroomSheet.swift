//
//  CreateClassroomSheet.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/26/25.
//

import SwiftUI

struct CreateClassroomSheet: View {
    
    @Environment(\.dismiss) private var dismiss
    
    let userId: String
    var onClassroomCreated: (() -> Void)? = nil
    
    @State private var classroomName: String = ""
    @State private var isCreating: Bool = false
    @State private var errorMessage: String? = nil
    
    private var trimmedClassroomName: String {
        let trimmedName = classroomName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let components = trimmedName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return components.joined(separator: " ")
    }
    
    private var isClassroomNameValid: Bool {
        let count = trimmedClassroomName.count
        return count >= 8 && count <= 150
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Classroom Name") {
                    TextField("Type Classroom Name", text: $classroomName)
                }
                
                Button {
                    createClassroom()
                } label: {
                    HStack {
                        Text("Create Classroom")
                        
                        if isCreating {
                            ProgressView()
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .disabled(!isClassroomNameValid || isCreating)
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
                    Text("Create Classroom")
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
    
    private func createClassroom() {
        withAnimation {
            isCreating = true
            errorMessage = nil
        }
        
        DataManager.shared.createClassroom(
            userId: userId,
            withClassroomName: trimmedClassroomName
        ) { result in
            DispatchQueue.main.async {
                
                withAnimation {
                    isCreating = false
                }
                
                switch result {
                
                case true:
                    dismiss()
                    onClassroomCreated?()
                    
                case false :
                    withAnimation {
                        errorMessage = "Name must be unique and 8–150 characters."
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
    CreateClassroomSheet(userId: "3rNFDKJebENEfHqVFg475bJXb9j1")
}
