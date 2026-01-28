import SwiftUI

/// Active workout view for tracking a live workout session
struct ActiveWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: WorkoutLogViewModel
    
    @State private var showDiscardAlert = false
    @State private var showCompleteAlert = false
    @State private var showAddExercise = false
    @State private var expandedExercises: Set<String> = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Timer Header
                timerHeader
                
                ScrollView {
                    VStack(spacing: 16) {
                        if let workout = viewModel.activeWorkout {
                            ForEach(Array(workout.exercises.enumerated()), id: \.element.id) { index, exercise in
                                ExerciseCard(
                                    exercise: exercise,
                                    exerciseIndex: index,
                                    isExpanded: expandedExercises.contains(exercise.id),
                                    isPR: viewModel.newPRs.contains(exercise.name),
                                    onToggle: {
                                        toggleExpanded(exercise.id)
                                    },
                                    onUpdateSet: { setIndex, reps, weight, isCompleted in
                                        viewModel.updateSet(
                                            exerciseIndex: index,
                                            setIndex: setIndex,
                                            reps: reps,
                                            weight: weight,
                                            isCompleted: isCompleted
                                        )
                                    },
                                    onAddSet: {
                                        viewModel.addSet(to: index)
                                    },
                                    onRemoveSet: { setIndex in
                                        viewModel.removeSet(from: index, at: setIndex)
                                    }
                                )
                            }
                            
                            // Add Exercise Button
                            Button(action: { showAddExercise = true }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Add Exercise")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color(.secondarySystemBackground))
                                .cornerRadius(Constants.UI.cornerRadius)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                
                // Bottom Actions
                bottomActions
            }
            .navigationTitle(viewModel.activeWorkout?.dayName ?? "Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard") {
                        showDiscardAlert = true
                    }
                    .foregroundStyle(.red)
                }
            }
            .alert("Discard Workout?", isPresented: $showDiscardAlert) {
                Button("Discard", role: .destructive) {
                    viewModel.discardWorkout()
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Your workout progress will be lost.")
            }
            .alert("Complete Workout?", isPresented: $showCompleteAlert) {
                Button("Complete") {
                    Task {
                        await viewModel.completeWorkout()
                        dismiss()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if !viewModel.newPRs.isEmpty {
                    Text("🎉 New PRs: \(viewModel.newPRs.joined(separator: ", "))")
                } else {
                    Text("Save this workout to your log?")
                }
            }
            .sheet(isPresented: $showAddExercise) {
                QuickAddExerciseSheet { exercise in
                    viewModel.addExercise(exercise)
                }
            }
            .onAppear {
                // Expand all exercises by default
                if let workout = viewModel.activeWorkout {
                    expandedExercises = Set(workout.exercises.map { $0.id })
                }
                // Refresh timer to show accurate time after backgrounding
                viewModel.refreshTimer()
            }
        }
        .interactiveDismissDisabled()
    }
    
    // MARK: - Timer Header
    
    private var timerHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Duration")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(viewModel.workoutTimer.formattedTimer)
                    .font(.title2.monospacedDigit())
                    .fontWeight(.semibold)
            }
            
            Spacer()
            
            if let workout = viewModel.activeWorkout {
                let completed = workout.exercises.reduce(0) { total, ex in
                    total + ex.completedSets.filter { $0.isCompleted }.count
                }
                let total = workout.exercises.reduce(0) { $0 + $1.completedSets.count }
                
                VStack(alignment: .trailing) {
                    Text("Sets")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(completed)/\(total)")
                        .font(.title2.monospacedDigit())
                        .fontWeight(.semibold)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
    }
    
    // MARK: - Bottom Actions
    
    private var bottomActions: some View {
        Button(action: { showCompleteAlert = true }) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                Text("Complete Workout")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.green)
            .foregroundStyle(.white)
            .cornerRadius(Constants.UI.cornerRadius)
        }
        .padding()
        .background(Color(.systemBackground))
    }
    
    private func toggleExpanded(_ id: String) {
        if expandedExercises.contains(id) {
            expandedExercises.remove(id)
        } else {
            expandedExercises.insert(id)
        }
    }
}

// MARK: - Exercise Card

struct ExerciseCard: View {
    let exercise: ExerciseLog
    let exerciseIndex: Int
    let isExpanded: Bool
    let isPR: Bool
    let onToggle: () -> Void
    let onUpdateSet: (Int, Int, Double, Bool) -> Void
    let onAddSet: () -> Void
    let onRemoveSet: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Button(action: onToggle) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(exercise.name)
                                .font(.headline)
                            
                            if isPR {
                                Text("PR!")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.yellow.gradient)
                                    .cornerRadius(4)
                            }
                        }
                        
                        let completed = exercise.completedSets.filter { $0.isCompleted }.count
                        Text("\(completed)/\(exercise.completedSets.count) sets")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
            .padding()
            
            if isExpanded {
                Divider()
                
                VStack(spacing: 8) {
                    // Set headers
                    HStack(spacing: 12) {
                        Text("Set")
                            .frame(width: 30)
                        Text("Previous")
                            .frame(width: 70)
                        Text("Weight")
                            .frame(width: 70)
                        Text("Reps")
                            .frame(width: 50)
                        Spacer()
                        Text("✓")
                            .frame(width: 30)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)
                    .padding(.top, 8)
                    
                    ForEach(Array(exercise.completedSets.enumerated()), id: \.element.id) { setIndex, set in
                        SetInputRow(
                            set: set,
                            setNumber: setIndex + 1,
                            onUpdate: { reps, weight, isCompleted in
                                onUpdateSet(setIndex, reps, weight, isCompleted)
                            },
                            onRemove: {
                                onRemoveSet(setIndex)
                            }
                        )
                    }
                    
                    Button(action: onAddSet) {
                        HStack {
                            Image(systemName: "plus")
                            Text("Add Set")
                        }
                        .font(.subheadline)
                        .foregroundStyle(.blue)
                    }
                    .padding(.vertical, 8)
                }
                .padding(.bottom)
            }
        }
        .background(Color(.secondarySystemBackground))
        .cornerRadius(Constants.UI.cornerRadius)
    }
}

// MARK: - Set Input Row

struct SetInputRow: View {
    let set: SetLog
    let setNumber: Int
    let onUpdate: (Int, Double, Bool) -> Void
    let onRemove: () -> Void
    
    @State private var repsText: String = ""
    @State private var weightText: String = ""
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(setNumber)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: 30)
            
            
            Text(set.previousPerformance ?? "\(set.targetReps)×\(Int(set.targetWeight))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 70)
                .minimumScaleFactor(0.8)
            
            TextField("0", text: $weightText)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 70)
                .onChange(of: weightText) { _, newValue in
                    let weight = Double(newValue) ?? set.weight
                    onUpdate(set.actualReps, weight, set.isCompleted)
                }
            
            TextField("0", text: $repsText)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
                .frame(width: 50)
                .onChange(of: repsText) { _, newValue in
                    let reps = Int(newValue) ?? set.actualReps
                    onUpdate(reps, set.weight, set.isCompleted)
                }
            
            Spacer()
            
            Button(action: {
                let newCompleted = !set.isCompleted
                onUpdate(
                    Int(repsText) ?? set.targetReps,
                    Double(weightText) ?? set.targetWeight,
                    newCompleted
                )
            }) {
                Image(systemName: set.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(set.isCompleted ? .green : .secondary)
            }
            .frame(width: 30)
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
        .background(set.isCompleted ? Color.green.opacity(0.1) : Color.clear)
        .onAppear {
            weightText = set.weight > 0 ? String(format: "%.0f", set.weight) : ""
            repsText = set.actualReps > 0 ? "\(set.actualReps)" : ""
        }
        .contextMenu {
            Button(role: .destructive, action: onRemove) {
                Label("Remove Set", systemImage: "trash")
            }
        }
    }
}

// MARK: - Quick Add Exercise Sheet

struct QuickAddExerciseSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onAdd: (Exercise) -> Void
    
    @State private var name = ""
    @State private var sets = 3
    @State private var reps = 10
    @State private var weight: Double = 0
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise") {
                    TextField("Exercise Name", text: $name)
                }
                
                Section("Target") {
                    Stepper("Sets: \(sets)", value: $sets, in: 1...20)
                    Stepper("Reps: \(reps)", value: $reps, in: 1...100)
                    
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("0", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 80)
                        Text("lbs")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Add Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let exercise = Exercise(
                            name: name.trimmed,
                            targetSets: sets,
                            targetReps: reps,
                            targetWeight: weight
                        )
                        onAdd(exercise)
                        dismiss()
                    }
                    .disabled(name.trimmed.isEmpty)
                }
            }
        }
        .presentationDetents([.medium])
    }
}

#Preview {
    ActiveWorkoutView(viewModel: WorkoutLogViewModel(userId: "preview"))
}
