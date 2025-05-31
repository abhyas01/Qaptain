//
//  ClassroomDetailView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/24/25.
//

import SwiftUI

struct ClassroomDetailView: View {
    
    let userId: String
    let documentId: String
    let createdAt: Date
    let createdByName: String
    let isCreator: Bool
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var didCopy = false
    @State private var didRegenerate = false
    @State private var isRegenerating = false
    
    @State private var isEditingName = false
    @State private var editedName: String
    @State private var isSavingEdit = false
    
    @State private var classroomName: String
    @State private var classroomPassword: String
    
    @State private var duplicateAlert: Bool = false
    
    @State private var isDeleting: Bool = false
    @State private var errorInDeleting: Bool = false
    @State private var deleteAlert: Bool = false
    
    init(userId: String,
         documentId: String,
         classroomName: String,
         createdAt: Date,
         createdByName: String,
         isCreator: Bool,
         password: String
    ) {
        self.userId = userId
        self.documentId = documentId
        self.classroomName = classroomName
        self.createdAt = createdAt
        self.createdByName = createdByName
        self.isCreator = isCreator
        
        self.editedName = classroomName
        self.classroomPassword = password
    }
    
    enum ButtonType: CaseIterable {
        case quizzes
        case people
        
        var getString: String {
            switch self {
            case .quizzes:
                return "Quizzes"
            case .people:
                return "People"
            }
        }
        
        var getIcon: Image {
            switch self {
            case .quizzes:
                return Image(systemName: "doc.text")
            case .people:
                return Image(systemName: "person.2.fill")
            }
        }
    }
    
    private var trimmedEditedName: String {
        let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        let components = trimmedName
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        return components.joined(separator: " ")
    }
    
    private var isEditedNameValid: Bool {
        let count = trimmedEditedName.count
        return count >= 8 && count <= 150
    }

    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack {
                    Spacer()
                    
                    VStack(spacing: 60) {
                        headerSection
                        
                        if isCreator {
                            passwordSection
                        }
                    
                        VStack(spacing: 20) {
                            ForEach(ButtonType.allCases, id: \.self) {
                                sectionRow(type: $0)
                            }
                        }
                        .padding(.horizontal)
                        
                        deleteButton
                    }
                    .padding()
                    
                    Spacer()
                }
                .frame(minHeight: geometry.size.height)
            }
        }
        
        .alert("Renaming Failed", isPresented: $duplicateAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("The classroom name must be unique among all classrooms you have created.")
        }
        
        .alert(isCreator ? "Are you sure?" : "Are you sure?", isPresented: $deleteAlert) {
            Button("Yes", role: .destructive) {
                if isCreator {
                    deleteThisClassroom()
                } else {
                    unenrollFromClass()
                }
            }
            Button("No", role: .cancel) {}
        } message: {
            Text(isCreator ?
                 "This Classroom will be permanently deleted." :
                 "You will be removed from this classroom. You can rejoin with the password anytime.")
        }
        
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(classroomName)                
                    .font(.headline)
                    .fontDesign(.rounded)
                    .foregroundStyle(.orange)
                    .fontWeight(.bold)
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

    
    private var headerSection: some View {
        VStack(spacing: 12) {
            HStack {
                if isEditingName {
                    
                    TextEditor(
                        text: $editedName
                    )
                    .font(.title2)
                    .border(.gray, width: 2)
                    .frame(maxHeight: 200)
                    .disabled(isSavingEdit)

                } else {
                    Text(classroomName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                }

                if isCreator {
                    VStack(spacing: 8) {
                        
                        Button {
                            if !isEditingName {
                                
                                withAnimation {
                                    isEditingName = true
                                }
                                
                            } else if isEditedNameValid {
                                
                                withAnimation {
                                    isSavingEdit = true
                                }
                                
                                DataManager.shared.updateClassroomName(
                                    documentId: documentId,
                                    userId: userId,
                                    withName: trimmedEditedName,
                                    completionHandler: { newName in
                                        
                                        DispatchQueue.main.async {
                                            
                                            withAnimation {
                                                isSavingEdit = false
                                                isEditingName = false
                                            }
                                            
                                            if let newName = newName {
                                                withAnimation {
                                                    classroomName = newName
                                                    editedName = newName
                                                }
                                                
                                            } else {
                                                withAnimation {
                                                    editedName = classroomName
                                                    duplicateAlert = true
                                                }
                                            }
                                        }
                                    }
                                )
                            }
                        } label: {
                            if !isSavingEdit {
                                Image(
                                    systemName:
                                        isEditingName ?
                                    "checkmark.circle.fill"
                                    : "pencil.circle.fill"
                                )
                                .font(.title2)
                                .tint(isEditingName ? .green : .accentColor)
                                
                            } else {
                                ProgressView()
                            }
                        }
                        .disabled(isSavingEdit || (isEditingName && !isEditedNameValid))
                        
                        if isEditingName {
                            Button {
                                withAnimation {
                                    isEditingName = false
                                    editedName = classroomName
                                }
                            } label: {
                                Image(systemName: "x.circle")
                                    .font(.title2)
                                    .tint(.gray)
                            }
                        }
                    }
                }
            }

            Text(createdByName)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Text(createdAt.formatted(date: .abbreviated, time: .shortened))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: Color.gray, radius: 4, x: 0, y: 2)
    }
    
    private func sectionRow(type: ButtonType) -> some View {
        NavigationLink {
            
            switch type {
            case .quizzes:
                QuizView(
                    userId: userId,
                    classroomId: documentId,
                    classroomName: classroomName,
                    createdByName: createdByName,
                    isCreator: isCreator
                )

            case .people:
                ClassMembersView(
                    classroomId: documentId,
                    isCreator: isCreator
                )
            }
            
        } label: {
            HStack {
                type.getIcon
                    .font(.title3)
                
                Text(type.getString)
                    .font(.body)
                
                Spacer()
                Image(systemName: "chevron.right")
            }
            .foregroundStyle(.orange)
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: Color.gray, radius: 2, x: 0, y: 1)
    }

    private var deleteButton: some View {
        Button {
            
            deleteAlert = true
            
        } label: {
            
            if isDeleting {
                
                HStack {
                    ProgressView()
                    Text(isCreator ? "Deleting..." : "Unenrolling...")
                }
                .fontWeight(.bold)
                .frame(maxWidth: .infinity)
                .padding(8)
                
            } else if errorInDeleting {
                
                Label(
                    isCreator ?
                        "Error occurred while deleting. Try again?" :
                        "Error occurred while unenrolling. Try again?",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .padding(8)
                
            } else {
                
                Text(isCreator ? "Delete Classroom" : "Unenroll from Classroom")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding(8)
                
            }
        }
        .disabled(isDeleting)
        .buttonStyle(.borderedProminent)
        .tint((isDeleting || errorInDeleting) ? .secondary : .red)
    }
    
    private var passwordSection: some View {
        VStack(alignment: .leading){
            
            HStack {
                Text("Password to join this class")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
                
                Spacer()
                
                if isRegenerating {
                    regenerateButton
                } else {
                    regenerateButton
                        .buttonStyle(.borderedProminent)
                }
            }
            .padding(.horizontal, 8)
            
            HStack {
                Text(classroomPassword)
                    .multilineTextAlignment(.leading)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .animation(.smooth, value: classroomPassword)
                
                Spacer()
                
                Button {
                    UIPasteboard.general.string = classroomPassword
                    withAnimation {
                        didCopy = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        withAnimation {
                            didCopy = false
                        }
                    }
                } label: {
                    Image(systemName: didCopy ? "checkmark.circle.fill" : "list.clipboard.fill")
                        .foregroundStyle(didCopy ? .green : .orange)
                        .transition(.scale)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.orange.opacity(0.3))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
    }
    
    private var regenerateButton: some View {
        Button {
            withAnimation {
                isRegenerating = true
            }
    
            DataManager.shared.regenerateClassroomPassword(
                documentId: documentId,
                completionHandler: { password in
                    
                    DispatchQueue.main.async {
                        
                        if let password = password {
                            withAnimation {
                                classroomPassword = password
                                didRegenerate = true
                                isRegenerating = false
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                                withAnimation {
                                    didRegenerate = false
                                }
                            }
                            
                        } else {
                            
                            withAnimation {
                                isRegenerating = false
                            }
                        }
                    }
                }
            )
        } label: {
            if !isRegenerating {
                
                Image(systemName: didRegenerate ?
                      "checkmark.circle.fill"
                      : "arrow.clockwise.circle.fill"
                )
                .transition(.scale)
                .foregroundColor(didRegenerate ? .green : .white)
                
            } else {
                
                ProgressView()
            }
        }
        .disabled(didRegenerate || isRegenerating)
    }
    
    private func deleteThisClassroom() {
        withAnimation {
            isDeleting = true
            errorInDeleting = false
        }

        DataManager.shared.deleteClassroom(
            classroomId: documentId,
            completionHandler: { success in
                
                DispatchQueue.main.async {
                    
                    if success {
                        
                        withAnimation {
                            isDeleting = false
                            dismiss()
                        }
                        
                    } else {
                        
                        withAnimation {
                            isDeleting = false
                            errorInDeleting = true
                        }
                        
                    }
                }
            }
        )
    }

    private func unenrollFromClass() {
        withAnimation {
            isDeleting = true
            errorInDeleting = false
        }

        DataManager.shared.removeMember(
            classroomId: documentId,
            userId: userId,
            completion: { success in
                
                DispatchQueue.main.async {
                    
                    if success {
                        
                        withAnimation {
                            isDeleting = false
                            dismiss()
                        }
                        
                    } else {
                        
                        withAnimation {
                            isDeleting = false
                            errorInDeleting = true
                        }
                        
                    }
                }
            }
        )
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

#Preview {
    ClassroomDetailView(
        userId: "3rNFDKJebENEfHqVFg475bJXb9j1",
        documentId: "gQatY3SaHOLK8vd9EUtl",
        // 150 chars max
        classroomName: "MPCS 51032 Advanced iOS Application Development (Autumn 2022) MPCS 51032 Advanced iOS Application Development (Autumn 2022) MPCS 51032 Advanced iOS De",
        createdAt: Date(),
        createdByName: "Abhyas Mall T.A. Binkowski",
        isCreator: true,
        password: "548789B9-BFE2-4008-95B3-FC36105049D2"
    )
}
