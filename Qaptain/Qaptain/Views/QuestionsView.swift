//
//  QuestionsView.swift
//  Qaptain
//
//  Created by Abhyas Mall on 5/29/25.
//

import SwiftUI

struct QuestionsView: View {
    
    let classroomId: String
    let userId: String
    let quizId: String
    let quizName: String
    
    @State var questions: [Question]
    
    let onDismiss: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var progress: CGFloat = 0
    @State private var currentIndex: Int = 0
    @State private var score: Int = 0
    @State private var presentScore: Bool = false
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: 20) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title)
                            .fontWeight(.black)
                            .foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(quizName)
                        .font(.title)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .foregroundStyle(.white)
                        .lineLimit(2)
                    
                    GeometryReader {
                        let size = $0.size
                        
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.black.opacity(0.2))
                            
                            RoundedRectangle(cornerRadius: 14)
                                .fill(.orange)
                                .frame(width: progress * size.width, alignment: .leading)
                        }
                    }
                    .frame(height: 35)
                        
                    Group {
                        ForEach(questions.indices, id: \.self) { index in
                            if currentIndex == index {
                                questionView(questions[currentIndex])
                                    .transition(.opacity)
                            }
                        }
                    }
                    .padding(.horizontal, -20)
                    
                    Button {
                        if currentIndex < (questions.count - 1) {
                            
                            withAnimation(.easeInOut(duration: 0.25)) {
                                currentIndex += 1
                            }
                            
                            withAnimation {
                                progress = (CGFloat(currentIndex) + 1) / CGFloat(questions.count)
                            }
                        } else if currentIndex == questions.count - 1 {
                            presentScore = true
                        }
                    } label: {
                        HStack {
                            Text(
                                currentIndex == questions.count - 1 ?
                                "Finish" :
                                "Next Question"
                            )
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .multilineTextAlignment(.center)
                            .fontWeight(.bold)
                            .padding(.vertical, 8)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(
                        currentIndex == questions.count - 1 ?
                        .green :
                        .none
                    )
                    .disabled(questions[currentIndex].tappedAnswer == "")
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 20)
                .frame(minHeight: geometry.size.height)
                .frame(maxWidth: .infinity, alignment: .top)
                .frame(maxWidth: .infinity, alignment: .center)
            }
            .background(Color(.systemGray2))
            .fullScreenCover(isPresented: $presentScore) {
                ScoreView(
                    score: score,
                    total: questions.count,
                    userId: userId,
                    classroomId: classroomId,
                    quizId: quizId
                ) {
                    dismiss()
                    onDismiss()
                }
            }
        }
    }
    
    private func questionView(_ question: Question) -> some View {
        VStack(spacing: 20) {
            Text("Question \(currentIndex + 1)/\(questions.count)")
                .font(.callout)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity,alignment: .leading)
            
            Text(question.question)
                .font(.title3)
                .fontWeight(.bold)
            
            VStack(spacing: 10) {
                ForEach(question.options, id: \.self) { option in
                    optionView(option, backgroundColor(for: option, in: question))
                        .contentShape(Rectangle())
                        .onTapGesture {
                            guard questions[currentIndex].tappedAnswer == "" else { return }
                            
                            if question.answer == option {
                                score += 1
                            }
                            
                            withAnimation {
                                questions[currentIndex].tappedAnswer = option
                            }
                        }
                }
            }
        }
        .padding(15)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal, 20)
    }
    
    private func optionView(_ option: String, _ tint: Color) -> some View {
        Text(option)
            .fontWeight(.bold)
            .foregroundStyle(Color(tint))
            .multilineTextAlignment(.leading)
            .lineLimit(nil)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 15)
            .padding(.vertical, 20)
            .background {
                RoundedRectangle(
                    cornerRadius: 12,
                    style: .continuous
                )
                .stroke(
                    tint,
                    lineWidth: tint != .primary ? 6 : 2
                )
                .fill(
                    tint != .primary ? .white : .clear
                )
            }
    }

    
    private func backgroundColor(for option: String, in question: Question) -> Color {
        if question.tappedAnswer == "" {
            return .primary
        } else if option == question.answer {
            return .green
        } else if option == question.tappedAnswer {
            return .red
        } else {
            return .primary
        }
    }
}

#Preview {
    QuestionsView(
        classroomId: "gQatY3SaHOLK8vd9EUtl",
        userId: "3rNFDKJebENEfHqVFg475bJXb9j1",
        quizId: "1f3OThYT1HzBjy1USPLQ",
        quizName: "Module - Judy and the other three were the first two I had g",
        questions: Array(
            repeating: Question(
                id: "sTJgp2PIuUdMpdPf7fmU",
                question: "When was Obi-Wan Kenobi born?",
                options: [
                    "58 BBY",
                    "59 BBY",
                    "None of the above"
                ],
                answer: "None of the above",
                tappedAnswer: ""
            ),
            count: 5
        )
    ) {}
}
