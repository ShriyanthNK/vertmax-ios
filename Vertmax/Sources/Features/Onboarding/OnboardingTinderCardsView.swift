import SwiftUI

private let tinderStatements = [
    "I've watched a hundred vertical jump videos and still don't have a real plan.",
    "I train hard, but I have no idea if I'm actually getting higher.",
    "I'm worried that if I push too hard, I'll get hurt again.",
    "I want it bad, but nothing I've tried has actually worked."
]

/// Screen 5: pain amplification via swipe. Purely a "this app gets me"
/// engagement beat — the agree/dismiss choice isn't scored or stored
/// anywhere; the value is in making the user nod along, not in the data.
struct OnboardingTinderCardsView: View {
    let onFinished: () -> Void
    @State private var index = 0
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        VStack(spacing: Spacing.lg) {
            VStack(spacing: Spacing.xxs) {
                Text("Which of these sound like you?")
                    .font(VertFont.screenTitle)
                    .foregroundStyle(.textPrimary)
                Text("Swipe right if it's true, left to skip.")
                    .font(VertFont.caption)
                    .foregroundStyle(.textMuted)
            }
            .padding(.top, Spacing.lg)

            Spacer(minLength: Spacing.md)

            ZStack {
                ForEach(cardIndices, id: \.self) { i in
                    card(for: i)
                        .zIndex(Double(-i))
                }
            }
            .frame(height: 260)

            Spacer(minLength: Spacing.md)

            HStack(spacing: Spacing.xl) {
                swipeButton(icon: "xmark", tint: .stopRed) { swipe(agree: false) }
                swipeButton(icon: "checkmark", tint: .voltGreen) { swipe(agree: true) }
            }
        }
    }

    private var cardIndices: [Int] {
        Array(index..<min(index + 2, tinderStatements.count)).reversed()
    }

    @ViewBuilder
    private func card(for i: Int) -> some View {
        if i == index {
            cardContent(i)
                .offset(dragOffset)
                .rotationEffect(.degrees(Double(dragOffset.width / 20)))
                .gesture(dragGesture)
        } else {
            cardContent(i)
                .scaleEffect(0.95)
                .opacity(0.6)
        }
    }

    private func cardContent(_ i: Int) -> some View {
        Text(tinderStatements[i])
            .font(VertFont.headline)
            .foregroundStyle(.textPrimary)
            .multilineTextAlignment(.center)
            .padding(Spacing.lg)
            .frame(maxWidth: .infinity)
            .frame(height: 220)
            .cardStyle(accent: i == index ? .voltGreen : nil)
            .padding(.horizontal, Spacing.lg)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in dragOffset = value.translation }
            .onEnded { value in
                if value.translation.width > 100 {
                    swipe(agree: true)
                } else if value.translation.width < -100 {
                    swipe(agree: false)
                } else {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { dragOffset = .zero }
                }
            }
    }

    private func swipe(agree: Bool) {
        withAnimation(.easeOut(duration: 0.25)) {
            dragOffset = CGSize(width: agree ? 500 : -500, height: 0)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            dragOffset = .zero
            if index < tinderStatements.count - 1 {
                index += 1
            } else {
                onFinished()
            }
        }
    }

    private func swipeButton(icon: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 56, height: 56)
                .background(Color.surface)
                .overlay(Circle().strokeBorder(tint.opacity(0.4), lineWidth: 1.5))
                .clipShape(Circle())
        }
    }
}
