import SwiftUI

/// Displays user level and progress bar toward next level
struct LevelProgressCard: View {
    let level: Int
    let currentXP: Int
    let requiredXP: Int
    let progress: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("LEVEL PROGRESS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppTheme.textTertiary)
                        .tracking(0.8)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("Level \(level)")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("\(currentXP)/\(requiredXP) XP")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(AppTheme.textSecondaryLight)
                    }
                }

                Spacer()

                // Bolt icon with background
                ZStack {
                    Circle()
                        .fill(AppTheme.energyOrange.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "bolt.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.energyOrange)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(AppTheme.progressTrackBackground)
                        .frame(height: 8)

                    // Progress fill with gradient
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppTheme.energyOrange,
                                    AppTheme.vibrantPurple
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 8)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                }
            }
            .frame(height: 8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(AppTheme.cardBackground)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        LevelProgressCard(
            level: 5,
            currentXP: 450,
            requiredXP: 1000,
            progress: 0.45
        )

        LevelProgressCard(
            level: 12,
            currentXP: 2800,
            requiredXP: 3200,
            progress: 0.875
        )
    }
    .padding()
    .background(Color.black)
}
