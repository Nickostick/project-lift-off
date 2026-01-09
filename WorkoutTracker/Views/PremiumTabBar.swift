import SwiftUI

/// Premium Custom TabBar - Clean minimal design
struct PremiumTabBar: View {
    @Binding var selectedTab: MainTabView.Tab
    let onStartWorkout: () -> Void

    @Namespace private var animation

    var body: some View {
        HStack(spacing: 0) {
            // Home
            MinimalTabButton(
                icon: "house.fill",
                isSelected: selectedTab == .home,
                color: AppTheme.primaryBlue
            ) {
                withAnimation(AppTheme.Animation.spring) {
                    selectedTab = .home
                }
            }

            Spacer()

            // Programs
            MinimalTabButton(
                icon: "doc.text.fill",
                isSelected: selectedTab == .programs,
                color: AppTheme.accentPurple
            ) {
                withAnimation(AppTheme.Animation.spring) {
                    selectedTab = .programs
                }
            }

            Spacer()

            // Start Workout Button (Center)
            startWorkoutButton
                .offset(y: -12)

            Spacer()

            // Reports
            MinimalTabButton(
                icon: "chart.bar.fill",
                isSelected: selectedTab == .reports,
                color: AppTheme.accentGreen
            ) {
                withAnimation(AppTheme.Animation.spring) {
                    selectedTab = .reports
                }
            }

            Spacer()

            // Settings
            MinimalTabButton(
                icon: "gearshape.fill",
                isSelected: selectedTab == .settings,
                color: AppTheme.accentOrange
            ) {
                withAnimation(AppTheme.Animation.spring) {
                    selectedTab = .settings
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(
            Rectangle()
                .fill(Color(hex: "0A0A0A"))
                .ignoresSafeArea()
                .overlay(
                    Rectangle()
                        .fill(Color(hex: "1A1A1A"))
                        .frame(height: 0.5),
                    alignment: .top
                )
        )
    }

    // MARK: - Start Workout Button

    private var startWorkoutButton: some View {
        Button(action: onStartWorkout) {
            Circle()
                .fill(AppTheme.primaryBlue)
                .frame(width: 44, height: 44)
                .overlay(
                    Image(systemName: "plus")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.black)
                )
        }
        .buttonStyle(ScaleButtonStyle())
        .accessibilityLabel("Start workout")
    }
}

// MARK: - Minimal Tab Button

struct MinimalTabButton: View {
    let icon: String
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 0) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? color : Color(hex: "666666"))
                    .symbolRenderingMode(.hierarchical)
                    .frame(height: 24)
            }
            .frame(width: 44)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Scale Button Style

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(AppTheme.Animation.spring, value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    VStack {
        Spacer()

        PremiumTabBar(
            selectedTab: .constant(.home),
            onStartWorkout: {}
        )
    }
    .background(Color(.systemBackground))
}
