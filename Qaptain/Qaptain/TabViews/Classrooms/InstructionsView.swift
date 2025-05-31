//
//  InstructionsView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/30/25.
//

import SwiftUI

/// Comprehensive onboarding and help view that introduces users to Qaptain's features
struct InstructionsView: View {

    // MARK: - Environment Dependencies

    /// Environment value to programmatically dismiss this modal view
    @Environment(\.dismiss) private var dismiss

    // MARK: - View Body

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                
                // Top Dismiss Button
                HStack {
                    Spacer()
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.gray)
                    }
                    .accessibilityLabel("Close instructions")
                }
                .padding(.horizontal)
                
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "graduationcap.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(.orange)
                    
                    Text("Welcome to Qaptain")
                        .font(.largeTitle.bold())
                        .foregroundStyle(.orange)
                    
                    Text("Your classroom quiz management companion")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 20)

                VStack(spacing: 16) {
                    
                    // For Teachers Section
                    sectionHeader(title: "For Teachers", icon: "person.fill.badge.plus")
                    
                    instructionCard(
                        icon: "plus.circle.fill",
                        title: "Create a Classroom",
                        description: "Switch to 'Teaching Classes' tab and tap 'Create a new class'. Give your classroom a unique name (8-150 characters) and we'll generate a secure password for students to join.",
                        color: .blue
                    )
                    
                    instructionCard(
                        icon: "doc.text.fill",
                        title: "Build Quizzes",
                        description: "Inside your classroom, tap the purple 'Add Quiz' card. Create multiple-choice questions with 2-5 options each, set deadlines, and publish when ready.",
                        color: .purple
                    )
                    
                    instructionCard(
                        icon: "chart.bar.fill",
                        title: "Monitor Results",
                        description: "View detailed statistics for each quiz including student scores, attempt times, and late submissions.",
                        color: .green
                    )
                    
                    instructionCard(
                        icon: "person.2.fill",
                        title: "Manage Members",
                        description: "View all classroom participants, remove students if needed, and regenerate the classroom password anytime from the classroom details page.",
                        color: .cyan
                    )
                    
                    // For Students Section
                    sectionHeader(title: "For Students", icon: "studentdesk")
                    
                    instructionCard(
                        icon: "key.fill",
                        title: "Join a Classroom",
                        description: "Go to 'Enrolled Classes' tab, tap 'Enroll in a new class', and enter the password provided by your teacher. You'll instantly see the classroom.",
                        color: .indigo
                    )
                    
                    instructionCard(
                        icon: "play.circle.fill",
                        title: "Take Quizzes",
                        description: "Tap on any available quiz to start. Answer each question carefully - your choice is locked once selected. Submit to see your immediate score and feedback.",
                        color: .orange
                    )
                    
                    instructionCard(
                        icon: "arrow.clockwise.circle.fill",
                        title: "Retake & Improve",
                        description: "You can retake quizzes multiple times before the deadline. All attempts are saved, and late submissions are clearly marked.",
                        color: .pink
                    )
                    
                    instructionCard(
                        icon: "person.3.fill",
                        title: "View Classmates",
                        description: "See who else is in your classroom by tapping 'People' in any classroom. View all enrolled students and your teacher.",
                        color: .teal
                    )
                    
                    // General Features Section
                    sectionHeader(title: "General Features", icon: "gear")
                    
                    instructionCard(
                        icon: "clock.fill",
                        title: "Real-time Updates",
                        description: "Pull down to refresh any screen. Quiz deadlines, new quizzes, and classroom changes appear instantly across all devices.",
                        color: .mint
                    )
                    
                    instructionCard(
                        icon: "shield.checkered",
                        title: "Secure & Private",
                        description: "Only classroom members can access quizzes, and teachers control who joins their classes.",
                        color: .red
                    )
                }

                // Footer
                VStack(spacing: 12) {
                    Text("Ready to Get Started?")
                        .font(.title2.bold())
                        .foregroundStyle(.orange)
                }
                .padding(.vertical, 24)
                
                // Bottom Dismiss Button
                Button {
                    dismiss()
                } label: {
                    Text("Get Started")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.orange)
                        .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding()
        }
        .onAppear {
            print("👁️ [InstructionsView] Instructions view appeared on screen")
            DataManager.shared.markAppAsLaunched()
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Section Header Component

    /// Creates a styled section header with icon and title
    /// Used to organize instruction content into logical categories
    /// - Parameters:
    ///   - title: The section title text to display
    ///   - icon: SF Symbol name for the section icon
    /// - Returns: A view containing the formatted section header
    private func sectionHeader(title: String, icon: String) -> some View {
        HStack {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.orange)
            
            Text(title)
                .font(.title2.bold())
                .foregroundStyle(.primary)
            
            Spacer()
        }
        .padding(.top, 8)
    }
    
    // MARK: - Instruction Card Component
    
    /// Creates a styled instruction card with icon, title, and description
    /// Provides consistent visual design for all feature explanations
    /// - Parameters:
    ///   - icon: SF Symbol name for the feature icon
    ///   - title: Feature title/name
    ///   - description: Detailed explanation of the feature
    ///   - color: Theme color for the icon and visual accent
    /// - Returns: A view containing the formatted instruction card
    private func instructionCard(icon: String, title: String, description: String, color: Color) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(description)")
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}

#Preview {
    InstructionsView()
}
