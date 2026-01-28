import SwiftUI

/// Full-screen level-up celebration view with confetti and animations
struct LevelUpView: View {
    let previousLevel: Int
    let newLevel: Int
    let onDismiss: () -> Void

    @State private var showContent = false
    @State private var confettiCounter = 0

    var body: some View {
        ZStack {
            // Dark background
            Color.black.opacity(0.95)
                .ignoresSafeArea()

            // Confetti overlay
            ConfettiView(counter: $confettiCounter)

            VStack(spacing: 32) {
                Spacer()

                // Level Up Badge
                VStack(spacing: 16) {
                    // Animated bolt icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppTheme.energyOrange,
                                        AppTheme.vibrantPurple
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 120, height: 120)
                            .scaleEffect(showContent ? 1.0 : 0.5)
                            .opacity(showContent ? 1.0 : 0.0)

                        Image(systemName: "bolt.fill")
                            .font(.system(size: 60, weight: .bold))
                            .foregroundStyle(.white)
                            .scaleEffect(showContent ? 1.0 : 0.5)
                            .rotationEffect(.degrees(showContent ? 0 : -180))
                    }

                    // "LEVEL UP!" text
                    Text("LEVEL UP!")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .tracking(2)
                        .scaleEffect(showContent ? 1.0 : 0.8)
                        .opacity(showContent ? 1.0 : 0.0)

                    // Level progression
                    HStack(spacing: 16) {
                        levelBadge(level: previousLevel, label: "FROM")

                        Image(systemName: "arrow.right")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundStyle(AppTheme.energyOrange)

                        levelBadge(level: newLevel, label: "TO", highlighted: true)
                    }
                    .scaleEffect(showContent ? 1.0 : 0.8)
                    .opacity(showContent ? 1.0 : 0.0)
                }

                Spacer()

                // Continue button
                Button(action: handleContinue) {
                    Text("Continue")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(AppTheme.primaryBlue)
                        )
                }
                .opacity(showContent ? 1.0 : 0.0)
                .padding(.horizontal, 40)
                .padding(.bottom, 40)
            }
        }
        .onAppear {
            performHapticFeedback()

            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showContent = true
            }

            // Trigger confetti
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                confettiCounter += 1
            }
        }
    }

    private func levelBadge(level: Int, label: String, highlighted: Bool = false) -> some View {
        VStack(spacing: 8) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(AppTheme.textTertiary)
                .tracking(0.8)

            Text("\(level)")
                .font(.system(size: 48, weight: .bold, design: .rounded))
                .foregroundStyle(highlighted ? AppTheme.energyOrange : .white)
        }
        .frame(width: 100)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(highlighted ? AppTheme.energyOrange : Color.clear, lineWidth: 2)
                )
        )
    }

    private func handleContinue() {
        performHapticFeedback()
        onDismiss()
    }

    private func performHapticFeedback() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
}

#Preview {
    LevelUpView(previousLevel: 4, newLevel: 5, onDismiss: {})
}
