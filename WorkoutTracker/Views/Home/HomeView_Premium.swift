import SwiftUI

/// Premium Home View - Clean minimal design inspired by professional fitness apps
struct HomeView_Premium: View {
    @ObservedObject var logViewModel: WorkoutLogViewModel
    @ObservedObject var programViewModel: ProgramViewModel
    @ObservedObject var levelViewModel: LevelViewModel

    @State private var showStartWorkout = false
    @State private var selectedProgram: Program?
    @State private var selectedDay: WorkoutDay?

    var body: some View {
        NavigationStack {
            ZStack {
                // Pure black background
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Header Section
                        headerSection
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        // Summary Cards Section
                        summaryCardsSection
                            .padding(.horizontal, 20)

                        // Stats Grid
                        statsGrid
                            .padding(.horizontal, 20)

                        // Quick Start Section
                        quickStartSection
                            .padding(.horizontal, 20)

                        // Recent Workouts
                        if !logViewModel.recentLogs.isEmpty {
                            recentWorkoutsSection
                                .padding(.top, 8)
                        }

                        // Spacer for tab bar
                        Color.clear.frame(height: 80)
                    }
                    .padding(.vertical, 16)
                }
            }
            .sheet(isPresented: $showStartWorkout) {
                StartWorkoutSheet(
                    programViewModel: programViewModel,
                    onSelect: { program, day in
                        logViewModel.startWorkout(from: day, program: program)
                        showStartWorkout = false
                    },
                    onQuickStart: {
                        logViewModel.startBlankWorkout()
                        showStartWorkout = false
                    }
                )
            }
            .fullScreenCover(isPresented: $logViewModel.isWorkoutActive) {
                ActiveWorkoutView(viewModel: logViewModel)
            }
            .fullScreenCover(isPresented: $levelViewModel.showLevelUpCelebration) {
                if let previousLevel = levelViewModel.levelUpPreviousLevel {
                    LevelUpView(
                        previousLevel: previousLevel,
                        newLevel: levelViewModel.currentLevel,
                        onDismiss: {
                            levelViewModel.dismissLevelUp()
                        }
                    )
                }
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(Date().formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: "666666"))
                    .textCase(.uppercase)
                    .tracking(0.5)

                Text("Daily Activity")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
            }

            Spacer()

            // Profile icon
            Circle()
                .fill(Color(hex: "1A1A1A"))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(Color(hex: "666666"))
                )
        }
    }

    // MARK: - Summary Cards Section

    private var summaryCardsSection: some View {
        VStack(spacing: 12) {
            // Level Progress Card
            if let userLevel = levelViewModel.userLevel {
                LevelProgressCard(
                    level: userLevel.currentLevel,
                    currentXP: userLevel.currentXP,
                    requiredXP: userLevel.xpForNextLevel,
                    progress: userLevel.progressToNextLevel
                )
            }

            // Weekly Progress Card
            weeklyProgressCard
        }
    }

    private var weeklyProgressCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("WEEKLY PROGRESS")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(Color(hex: "666666"))
                        .tracking(0.8)

                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("\(logViewModel.workoutsThisWeek)")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundStyle(.white)

                        Text("workouts")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(Color(hex: "999999"))
                    }
                }

                Spacer()

                // Icon with background
                ZStack {
                    Circle()
                        .fill(AppTheme.primaryBlue.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.primaryBlue)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1A1A1A"))
        )
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: 12) {
            // Volume Card
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "scalemass.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: "666666"))

                    Spacer()

                    // Small trend indicator
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                        Text(logViewModel.workoutsThisWeek > 0 ? "+2.4k" : "0")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.successGreen)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text(String(format: "%.1fk", logViewModel.totalVolumeThisWeek / 1000))
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("VOLUME")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: "666666"))
                        .tracking(0.5)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "1A1A1A"))
            )

            // PRs Card
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color(hex: "666666"))

                    Spacer()

                    // Small indicator
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                        Text(logViewModel.personalRecords.isEmpty ? "0" : "+\(min(logViewModel.personalRecords.count, 5))")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(AppTheme.vibrantPurple)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(logViewModel.personalRecords.count)")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(.white)

                    Text("PERSONAL RECORDS")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: "666666"))
                        .tracking(0.5)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .frame(height: 140)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(hex: "1A1A1A"))
            )
        }
    }

    // MARK: - Quick Start Section

    private var quickStartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("QUICK START")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "666666"))
                    .tracking(0.8)

                Spacer()

                Text("FAVORITES")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: "444444"))
                    .tracking(0.5)
            }

            // Start Workout Card
            Button(action: { showStartWorkout = true }) {
                HStack {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "figure.strengthtraining.traditional")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(AppTheme.primaryBlue)

                            Text("STRENGTH")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(Color(hex: "666666"))
                                .tracking(0.8)
                        }

                        Text("Start Workout")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundStyle(.white)

                        Text("Choose a template or quick start")
                            .font(.system(size: 13, weight: .regular))
                            .foregroundStyle(Color(hex: "999999"))
                    }

                    Spacer()

                    // Play button
                    Image(systemName: "play.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color(hex: "2A2A2A"))
                        )
                }
                .padding(18)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(hex: "1A1A1A"))
                )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Recent Workouts Section

    private var recentWorkoutsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("RECENT")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "666666"))
                    .tracking(0.8)

                Spacer()

                NavigationLink {
                    LogListView(viewModel: logViewModel)
                } label: {
                    HStack(spacing: 4) {
                        Text("View All")
                            .font(.system(size: 13, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(Color(hex: "666666"))
                }
            }
            .padding(.horizontal, 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(logViewModel.recentLogs.prefix(5)) { log in
                        NavigationLink {
                            LogDetailView(log: log)
                        } label: {
                            MinimalWorkoutCard(log: log)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Minimal Workout Card

struct MinimalWorkoutCard: View {
    let log: WorkoutLog

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Date
            VStack(alignment: .leading, spacing: 2) {
                Text(log.startedAt.formatted(.dateTime.day()))
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(.white)
                Text(log.startedAt.formatted(.dateTime.month(.abbreviated).year()))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: "666666"))
                    .textCase(.uppercase)
            }

            Spacer()

            // Workout name
            Text(log.dayName)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(.white)
                .lineLimit(2)
                .minimumScaleFactor(0.9)

            // Stats
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(log.exercises.count)")
                        .font(.system(size: 12, weight: .semibold))
                    Text("exercises")
                        .font(.system(size: 12, weight: .regular))
                }
                .foregroundStyle(Color(hex: "999999"))

                HStack(spacing: 6) {
                    Text(log.formattedDuration)
                        .font(.system(size: 12, weight: .regular))
                }
                .foregroundStyle(Color(hex: "999999"))
            }
        }
        .padding(16)
        .frame(width: 160, height: 180)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1A1A1A"))
        )
    }
}

// MARK: - Preview

#Preview {
    HomeView_Premium(
        logViewModel: WorkoutLogViewModel(userId: "preview"),
        programViewModel: ProgramViewModel(userId: "preview"),
        levelViewModel: LevelViewModel(userId: "preview")
    )
}
