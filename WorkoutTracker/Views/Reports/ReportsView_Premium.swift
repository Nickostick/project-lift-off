import SwiftUI
import Charts

/// Premium 2026 ReportsView - Bold gradient aesthetic with energetic stats
struct ReportsView_Premium: View {
    @StateObject private var viewModel: ReportsViewModel
    @ObservedObject var logViewModel: WorkoutLogViewModel

    @State private var selectedExercise: String?
    @State private var showExportOptions = false

    init(userId: String, logViewModel: WorkoutLogViewModel) {
        _viewModel = StateObject(wrappedValue: ReportsViewModel(userId: userId))
        self.logViewModel = logViewModel
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Pure black background
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                            .padding(.horizontal, 16)
                            .padding(.top, 8)

                        // Time range selector
                        timeRangePicker
                            .padding(.horizontal, 16)

                        // Summary stats grid
                        summaryStatsGrid
                            .padding(.horizontal, 16)

                        // Charts section
                        if !viewModel.weeklyVolumeData.isEmpty {
                            weeklyVolumeChart
                        }

                        if !viewModel.workoutFrequencyData.isEmpty {
                            workoutFrequencyChart
                        }

                        // Personal Records
                        prSection
                            .padding(.horizontal, 16)

                        // Exercise Progress
                        exerciseProgressSection

                        // Spacer for tab bar
                        Color.clear.frame(height: 80)
                    }
                    .padding(.vertical, 16)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    NavigationLink {
                        LogListView(viewModel: logViewModel)
                    } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 20))
                            .foregroundStyle(AppTheme.neonGreen)
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button(action: {
                            Task { await viewModel.exportToCSV() }
                        }) {
                            Label("Export CSV", systemImage: "tablecells")
                        }

                        Button(action: {
                            Task { await viewModel.exportToPDF() }
                        }) {
                            Label("Export PDF", systemImage: "doc.richtext")
                        }
                    } label: {
                        Image(systemName: "square.and.arrow.up.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(AppTheme.primaryGradient)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .refreshable {
                await viewModel.loadReportData()
            }
            .task {
                await viewModel.loadReportData()
            }
            .sheet(isPresented: $viewModel.showExportSheet) {
                if let url = viewModel.exportURL {
                    ShareSheet(items: [url])
                }
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(AppTheme.neonGreen)
                }
            }
            .alert("Error", isPresented: $viewModel.showError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage)
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "666666"))

                Text("ANALYTICS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "666666"))
                    .tracking(0.8)
            }

            Text("Progress")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.white)

            Text("Track your performance and achievements over time.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(hex: "999999"))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Time Range Picker

    private var timeRangePicker: some View {
        HStack(spacing: 0) {
            ForEach(ReportsViewModel.TimeRange.allCases, id: \.self) { range in
                Button(action: {
                    withAnimation(AppTheme.Animation.spring) {
                        viewModel.selectedTimeRange = range
                        Task { await viewModel.loadReportData() }
                    }
                }) {
                    Text(range.shortLabel)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(viewModel.selectedTimeRange == range ? AppTheme.darkBackground : Color(hex: "666666"))
                        .frame(maxWidth: .infinity)
                        .frame(height: 44)
                        .background(
                            viewModel.selectedTimeRange == range
                                ? AppTheme.neonGreen
                                : Color.clear
                        )
                        .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(12)
    }

    // MARK: - Summary Stats Grid

    private var summaryStatsGrid: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                MinimalStatCard(
                    title: "WORKOUTS",
                    value: "\(viewModel.totalWorkouts)",
                    icon: "figure.strengthtraining.traditional"
                )

                MinimalStatCard(
                    title: "VOLUME",
                    value: formatVolumeShort(viewModel.totalVolume),
                    icon: "scalemass.fill",
                    subtitle: "lbs total"
                )
            }
            .frame(height: 140)

            HStack(spacing: 12) {
                MinimalStatCard(
                    title: "AVG DURATION",
                    value: viewModel.averageWorkoutDuration.formattedDuration,
                    icon: "clock.fill"
                )

                MinimalStatCard(
                    title: "THIS WEEK",
                    value: "\(viewModel.workoutsThisWeek)",
                    icon: "calendar",
                    subtitle: "workouts"
                )
            }
            .frame(height: 140)
        }
    }

    // MARK: - Weekly Volume Chart

    private var weeklyVolumeChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("WEEKLY VOLUME")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "666666"))
                .tracking(0.8)
                .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 12) {
                Chart(viewModel.weeklyVolumeData) { point in
                    BarMark(
                        x: .value("Week", point.weekLabel),
                        y: .value("Volume", point.volume)
                    )
                    .foregroundStyle(AppTheme.successGreen)
                    .cornerRadius(6)
                }
                .frame(height: 200)
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundStyle(Color(hex: "2A2A2A"))
                        AxisValueLabel {
                            if let volume = value.as(Double.self) {
                                Text(formatVolume(volume))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(Color(hex: "666666"))
                            }
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: "666666"))
                    }
                }
                .padding(20)
            }
            .background(Color(hex: "1A1A1A"))
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - Workout Frequency Chart

    private var workoutFrequencyChart: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("THIS WEEK'S ACTIVITY")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "666666"))
                .tracking(0.8)
                .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 12) {
                Chart(viewModel.workoutFrequencyData) { point in
                    BarMark(
                        x: .value("Day", point.dayLabel),
                        y: .value("Workouts", point.count)
                    )
                    .foregroundStyle(
                        point.count > 0
                            ? AppTheme.primaryBlue
                            : Color(hex: "2A2A2A")
                    )
                    .cornerRadius(6)
                }
                .frame(height: 180)
                .chartYScale(domain: 0...3)
                .chartYAxis {
                    AxisMarks(position: .leading, values: [0, 1, 2, 3]) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 1, dash: [5]))
                            .foregroundStyle(Color(hex: "2A2A2A"))
                        AxisValueLabel()
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: "666666"))
                    }
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel()
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color(hex: "666666"))
                    }
                }
                .padding(20)
            }
            .background(Color(hex: "1A1A1A"))
            .cornerRadius(16)
            .padding(.horizontal, 16)
        }
    }

    // MARK: - PR Section

    private var prSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("PERSONAL RECORDS")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "666666"))
                    .tracking(0.8)

                Spacer()

                Text("\(viewModel.allPRs.count) TOTAL")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color(hex: "666666"))
                    .tracking(0.5)
            }

            if viewModel.allPRs.isEmpty {
                emptyPRsView
            } else {
                VStack(spacing: 12) {
                    ForEach(viewModel.recentPRs) { pr in
                        MinimalPRCard(
                            exerciseName: pr.exerciseName,
                            record: pr.formattedRecord,
                            achievedAt: pr.achievedAt.formattedRelative,
                            estimated1RM: "\(String(format: "%.0f", pr.estimated1RM)) lbs"
                        )
                    }
                }
            }
        }
    }

    private var emptyPRsView: some View {
        VStack(spacing: 16) {
            Image(systemName: "trophy")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color(hex: "444444"))

            Text("Complete workouts to set PRs")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color(hex: "999999"))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(16)
    }

    // MARK: - Exercise Progress Section

    private var exerciseProgressSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("EXERCISE PROGRESS")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color(hex: "666666"))
                .tracking(0.8)
                .padding(.horizontal, 16)

            if viewModel.allPRs.isEmpty {
                emptyExerciseProgressView
                    .padding(.horizontal, 16)
            } else {
                // Exercise selector chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(Array(Set(viewModel.allPRs.map { $0.exerciseName })).sorted(), id: \.self) { exercise in
                            Button(action: {
                                withAnimation(AppTheme.Animation.spring) {
                                    selectedExercise = exercise
                                    Task { await viewModel.loadExerciseProgress(exerciseName: exercise) }
                                }
                            }) {
                                MinimalExerciseChip(
                                    name: exercise,
                                    isSelected: selectedExercise == exercise
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 16)
                }

                // Progress chart for selected exercise
                if let exercise = selectedExercise,
                   let progress = viewModel.exerciseProgressData.first(where: { $0.exerciseName == exercise }),
                   !progress.dataPoints.isEmpty {
                    ProgressChartView(progress: progress)
                        .padding(.horizontal, 16)
                }
            }
        }
    }

    private var emptyExerciseProgressView: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color(hex: "444444"))

            Text("Exercise progress charts will appear once you log workouts")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color(hex: "999999"))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 180)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(16)
    }

    // MARK: - Helpers

    private func formatVolume(_ volume: Double) -> String {
        if volume >= 1000 {
            return String(format: "%.0fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }

    private func formatVolumeShort(_ volume: Double) -> String {
        if volume >= 1_000_000 {
            return String(format: "%.1fM", volume / 1_000_000)
        } else if volume >= 1000 {
            return String(format: "%.1fk", volume / 1000)
        }
        return String(format: "%.0f", volume)
    }
}

// MARK: - Minimal Stat Card

struct MinimalStatCard: View {
    let title: String
    let value: String
    let icon: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color(hex: "666666"))

                Spacer()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(.white)

                HStack(spacing: 4) {
                    Text(title)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundStyle(Color(hex: "666666"))
                        .tracking(0.5)

                    if let subtitle = subtitle {
                        Text("·")
                            .foregroundStyle(Color(hex: "444444"))
                        Text(subtitle)
                            .font(.system(size: 10, weight: .regular))
                            .foregroundStyle(Color(hex: "999999"))
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(16)
    }
}

// MARK: - Minimal PR Card

struct MinimalPRCard: View {
    let exerciseName: String
    let record: String
    let achievedAt: String
    let estimated1RM: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text(exerciseName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white)

                Text(record)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(hex: "999999"))

                Text(achievedAt)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color(hex: "666666"))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text("1RM EST.")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color(hex: "666666"))
                    .tracking(0.5)

                Text(estimated1RM)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppTheme.vibrantPurple)
            }
        }
        .padding(16)
        .background(Color(hex: "1A1A1A"))
        .cornerRadius(16)
    }
}

// MARK: - Minimal Exercise Chip

struct MinimalExerciseChip: View {
    let name: String
    let isSelected: Bool

    var body: some View {
        Text(name)
            .font(.system(size: 13, weight: isSelected ? .semibold : .medium))
            .foregroundStyle(isSelected ? .white : Color(hex: "999999"))
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                isSelected
                    ? Color(hex: "2A2A2A")
                    : Color(hex: "1A1A1A")
            )
            .cornerRadius(20)
    }
}

// MARK: - Preview

#Preview {
    ReportsView_Premium(
        userId: "preview",
        logViewModel: WorkoutLogViewModel(userId: "preview")
    )
}
