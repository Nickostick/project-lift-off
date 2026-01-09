import SwiftUI

/// Premium ProgramListView - Clean minimal library design
struct ProgramListView_Premium: View {
    @ObservedObject var viewModel: ProgramViewModel

    @State private var showAddProgram = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var programToEdit: Program?
    @State private var programToDelete: Program?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            ZStack {
                // Pure black background
                Color.black.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    // IMPORTANT: Padding is applied to individual sections, not the container VStack.
                    // This pattern prevents NavigationLink labels from expanding edge-to-edge,
                    // which can happen when container-level padding is used with certain modifiers.
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                            .padding(.horizontal, 20)
                            .padding(.top, 8)

                        if viewModel.programs.isEmpty && !viewModel.isLoading {
                            emptyStateView
                                .padding(.horizontal, 20)
                        } else {
                            // Routines List
                            routinesSection
                                .padding(.horizontal, 20)
                        }

                        // Add Template Button
                        addTemplateButton
                            .padding(.horizontal, 20)

                        // Spacer for tab bar
                        Color.clear.frame(height: 80)
                    }
                    .padding(.vertical, 16)
                }
            }
            .sheet(isPresented: $showAddProgram) {
                ProgramFormView(viewModel: viewModel, program: nil)
            }
            .sheet(item: $programToEdit) { program in
                ProgramFormView(viewModel: viewModel, program: program)
            }
            .sheet(isPresented: $showShareSheet) {
                ShareSheet(items: shareItems)
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
            .alert("Delete Program?", isPresented: $showDeleteConfirmation, presenting: programToDelete) { program in
                Button("Cancel", role: .cancel) {
                    programToDelete = nil
                }
                Button("Delete", role: .destructive) {
                    Task {
                        await viewModel.deleteProgram(program)
                        programToDelete = nil
                    }
                }
            } message: { program in
                Text("This will permanently delete \"\(program.name)\" and all \(program.days.count) days inside it. This action cannot be undone.")
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color(hex: "666666"))

                Text("LIBRARY")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color(hex: "666666"))
                    .tracking(0.8)
            }

            Text("Workout\nTemplates")
                .font(.system(size: 32, weight: .semibold))
                .foregroundStyle(.white)
                .lineSpacing(2)

            Text("Select a routine from your collection to begin training.")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(Color(hex: "999999"))
                .padding(.top, 4)
        }
    }

    // MARK: - Empty State

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color(hex: "444444"))

            VStack(spacing: 8) {
                Text("No Templates Yet")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)

                Text("Create your first workout program")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color(hex: "999999"))
            }
        }
        .frame(height: 240)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: "1A1A1A"))
        )
    }

    // MARK: - Routines Section

    private var routinesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Section header with sort indicator
            HStack {
                Text("YOUR ROUTINES")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color(hex: "666666"))
                    .tracking(0.8)

                Spacer()

                Text("SORT: LAST USED")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: "444444"))
                    .tracking(0.5)
            }

            // Program cards with navigation and context menu
            ForEach(viewModel.filteredPrograms) { program in
                NavigationLink {
                    ProgramDetailView_Premium(program: program, viewModel: viewModel)
                } label: {
                    MinimalProgramCard(program: program)
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button(action: {
                        programToEdit = program
                    }) {
                        Label("Edit", systemImage: "pencil")
                    }

                    Button(action: {
                        Task { await viewModel.copyProgram(program) }
                    }) {
                        Label("Copy", systemImage: "doc.on.doc")
                    }

                    Button(action: {
                        shareItems = viewModel.getShareItems(for: program)
                        showShareSheet = true
                    }) {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }

                    Divider()

                    Button(role: .destructive, action: {
                        programToDelete = program
                        showDeleteConfirmation = true
                    }) {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
    }

    // MARK: - Add Template Button

    private var addTemplateButton: some View {
        Button(action: { showAddProgram = true }) {
            // Using HStack with Spacers instead of .frame(maxWidth: .infinity)
            // This approach properly respects parent padding
            HStack {
                Spacer()

                HStack(spacing: 10) {
                    Image(systemName: "plus")
                        .font(.system(size: 14, weight: .semibold))

                    Text("NEW TEMPLATE")
                        .font(.system(size: 13, weight: .bold))
                        .tracking(0.5)
                }

                Spacer()
            }
            .foregroundStyle(Color(hex: "1A1A1A"))
            .frame(height: 48)
            .background(.white)
            .cornerRadius(24)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Minimal Program Card

/// Displays a program card with workout details and a play button
/// Uses .fixedSize(horizontal: true) to prevent edge-to-edge expansion within NavigationLink
struct MinimalProgramCard: View {
    let program: Program

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 12) {
                // Category badge
                HStack(spacing: 6) {
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(size: 10, weight: .semibold))

                    Text("STRENGTH")
                        .font(.system(size: 10, weight: .bold))
                        .tracking(0.5)
                }
                .foregroundStyle(Color(hex: "666666"))

                // Program name
                Text(program.name)
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Exercise list preview
                Text(exercisePreview)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color(hex: "999999"))
                    .lineLimit(1)

                // Stats row
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Text("DURATION")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color(hex: "666666"))

                        Text("\(program.days.count * 40) MIN")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.energyOrange)
                    }
                    .fixedSize()

                    HStack(spacing: 4) {
                        Text("VOLUME")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color(hex: "666666"))

                        Text("\(totalExercises) KG")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.successGreen)
                    }
                    .fixedSize()

                    HStack(spacing: 4) {
                        Text("EXERCISES")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(Color(hex: "666666"))

                        Text("\(totalExercises) ITEMS")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(AppTheme.vibrantPurple)
                    }
                    .fixedSize()
                }
            }

            // Play button
            Image(systemName: "play.fill")
                .font(.system(size: 14))
                .foregroundStyle(Color(hex: "666666"))
                .frame(width: 36, height: 36)
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
        // fixedSize prevents the card from expanding to fill available width
        // This ensures the card respects parent padding when used in NavigationLink
        .fixedSize(horizontal: true, vertical: false)
    }

    private var totalExercises: Int {
        program.days.reduce(0) { $0 + $1.exercises.count }
    }

    private var exercisePreview: String {
        let allExercises = program.days.flatMap { $0.exercises }
        let names = allExercises.prefix(3).map { $0.name }
        return names.joined(separator: ", ")
    }
}

// MARK: - Premium Program Detail View

struct ProgramDetailView_Premium: View {
    let program: Program
    @ObservedObject var viewModel: ProgramViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var showAddDay = false
    @State private var dayToEdit: WorkoutDay?
    @State private var showEditProgram = false
    @State private var showDeleteConfirmation = false

    var body: some View {
        ZStack {
            // Background
            AppTheme.darkBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Hero header
                    programHeader

                    // Sessions section
                    daysSection
                }
                .padding(AppTheme.Layout.screenPadding)
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button(action: { showAddDay = true }) {
                        Label("Add Day", systemImage: "plus")
                    }

                    Button(action: { showEditProgram = true }) {
                        Label("Edit Program", systemImage: "pencil")
                    }

                    Divider()

                    Button(role: .destructive, action: {
                        showDeleteConfirmation = true
                    }) {
                        Label("Delete Program", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.neonGreen)
                }
            }
        }
        .sheet(isPresented: $showAddDay) {
            WorkoutDayFormView(viewModel: viewModel, program: program, day: nil)
        }
        .sheet(item: $dayToEdit) { day in
            WorkoutDayFormView(viewModel: viewModel, program: program, day: day)
        }
        .sheet(isPresented: $showEditProgram) {
            ProgramFormView(viewModel: viewModel, program: program)
        }
        .alert("Delete Program?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                Task {
                    await viewModel.deleteProgram(program)
                    dismiss()
                }
            }
        } message: {
            Text("This will permanently delete \"\(program.name)\" and all \(program.days.count) sessions inside it. This action cannot be undone.")
        }
    }

    // MARK: - Program Header

    private var programHeader: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !program.description.isEmpty {
                Text(program.description)
                    .font(AppTheme.Typography.callout)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            HStack(spacing: 12) {
                // Sessions stat
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(program.days.count)")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Label("Days", systemImage: "calendar")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.Layout.cardCornerRadius)

                // Exercises stat
                VStack(alignment: .leading, spacing: 4) {
                    let totalExercises = program.days.reduce(0) { $0 + $1.exercises.count }
                    Text("\(totalExercises)")
                        .font(.system(size: 32, weight: .semibold, design: .rounded))
                        .foregroundStyle(AppTheme.textPrimary)
                    Label("Exercises", systemImage: "dumbbell.fill")
                        .font(AppTheme.Typography.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(AppTheme.cardBackground)
                .cornerRadius(AppTheme.Layout.cardCornerRadius)
            }
        }
    }

    // MARK: - Sessions Section

    private var daysSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Workout Days")
                    .font(AppTheme.Typography.title2)
                    .fontWeight(.medium)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Button(action: { showAddDay = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(AppTheme.neonGreen)
                }
            }

            if program.days.isEmpty {
                emptyDaysView
            } else {
                ForEach(program.days.sorted(by: { $0.order < $1.order })) { day in
                    NavigationLink {
                        WorkoutDayView(program: program, day: day, viewModel: viewModel)
                    } label: {
                        PremiumDayCard(day: day)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button(action: {
                            dayToEdit = day
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive, action: {
                            Task { await viewModel.deleteDay(from: program, day: day) }
                        }) {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }

    private var emptyDaysView: some View {
        VStack(spacing: 16) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(AppTheme.textSecondary)

            Text("No days yet")
                .font(AppTheme.Typography.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Button("Add Day") {
                showAddDay = true
            }
            .buttonStyle(.borderedProminent)
            .tint(AppTheme.neonGreen)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(AppTheme.cardBackground)
        .cornerRadius(AppTheme.Layout.cardCornerRadius)
    }
}

// MARK: - Preview

#Preview("Program List") {
    ProgramListView_Premium(viewModel: ProgramViewModel(userId: "preview"))
}

#Preview("Program Detail") {
    NavigationStack {
        ProgramDetailView_Premium(
            program: Program(
                userId: "preview",
                name: "Power Building 12-Week",
                description: "Strength and hypertrophy focused program for serious lifters",
                days: [
                    WorkoutDay(name: "Push Day A", exercises: [
                        Exercise(name: "Bench Press", targetSets: 4, targetReps: 8, targetWeight: 185),
                        Exercise(name: "Incline Dumbbell Press", targetSets: 3, targetReps: 10)
                    ], order: 0),
                    WorkoutDay(name: "Pull Day", exercises: [
                        Exercise(name: "Deadlift", targetSets: 5, targetReps: 5, targetWeight: 315)
                    ], order: 1),
                    WorkoutDay(name: "Leg Day", exercises: [], order: 2)
                ]
            ),
            viewModel: ProgramViewModel(userId: "preview")
        )
    }
}
