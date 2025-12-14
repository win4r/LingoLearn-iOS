//
//  AnswerOptionButton.swift
//  LingoLearn
//
//  Created by charles qin on 12/14/25.
//

import SwiftUI

enum AnswerState {
    case normal
    case selected
    case correct
    case wrong
    case disabled
}

struct AnswerOptionButton: View {
    let text: String
    let state: AnswerState
    let action: () -> Void

    private var backgroundColor: Color {
        switch state {
        case .normal:
            return Color(.systemBackground)
        case .selected:
            return Color.accentColor.opacity(0.1)
        case .correct:
            return Color.green.opacity(0.1)
        case .wrong:
            return Color.red.opacity(0.1)
        case .disabled:
            return Color.gray.opacity(0.05)
        }
    }

    private var borderColor: Color {
        switch state {
        case .normal:
            return Color.gray.opacity(0.3)
        case .selected:
            return Color.accentColor
        case .correct:
            return Color.green
        case .wrong:
            return Color.red
        case .disabled:
            return Color.gray.opacity(0.2)
        }
    }

    private var icon: String? {
        switch state {
        case .correct:
            return "checkmark.circle.fill"
        case .wrong:
            return "xmark.circle.fill"
        default:
            return nil
        }
    }

    private var iconColor: Color {
        switch state {
        case .correct:
            return .green
        case .wrong:
            return .red
        default:
            return .clear
        }
    }

    var body: some View {
        Button(action: action) {
            HStack {
                Text(text)
                    .font(.body)
                    .foregroundStyle(state == .disabled ? .secondary : .primary)
                    .multilineTextAlignment(.leading)

                Spacer()

                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundStyle(iconColor)
                        .font(.title3)
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: 2)
            )
        }
        .disabled(state == .disabled || state == .correct || state == .wrong)
    }
}

#Preview {
    VStack(spacing: 16) {
        AnswerOptionButton(text: "Hello", state: .normal, action: {})
        AnswerOptionButton(text: "Selected", state: .selected, action: {})
        AnswerOptionButton(text: "Correct Answer", state: .correct, action: {})
        AnswerOptionButton(text: "Wrong Answer", state: .wrong, action: {})
        AnswerOptionButton(text: "Disabled", state: .disabled, action: {})
    }
    .padding()
}
