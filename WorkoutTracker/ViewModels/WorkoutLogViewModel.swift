import Foundation
import Combine
import FirebaseFirestore

/// ViewModel for workout logging and log history
@MainActor
final class WorkoutLogViewModel: ObservableObject, ViewModelErrorHandling {

    // MARK: - Published Properties
    @Published var logs: [WorkoutLog] = []
    @Published var activeWorkout: WorkoutLog?
    @Published var personalRecords: [PersonalRecord] = []
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var workoutTimer: TimeInterval = 0
    @Published var isWorkoutActive = false
    @Published var newPRs: [String] = [] // Exercise names with new PRs

    // MARK: - Dependencies
    private let firestoreManager: FirestoreManager
    private let userId: String
    weak var levelViewModel: LevelViewModel?
    private var cancellables = Set<AnyCancellable>()
    private var listenerRegistrations: [ListenerRegistration] = []
    private var timerCancellable: AnyCancellable?
    private var workoutStartTime: Date? // Store start time for accurate duration

    // MARK: - Persistence Keys
    private static let activeWorkoutKey = "activeWorkout"
    private static let workoutStartTimeKey = "activeWorkoutStartTime"

    // MARK: - Computed Properties
    var recentLogs: [WorkoutLog] {
        Array(logs.prefix(10))
    }

    var todaysLogs: [WorkoutLog] {
        logs.filter { $0.startedAt.isToday }
    }

    var thisWeeksLogs: [WorkoutLog] {
        logs.filter { $0.startedAt.isThisWeek }
    }

    var totalVolumeThisWeek: Double {
        thisWeeksLogs.reduce(0) { $0 + $1.totalVolume }
    }

    var workoutsThisWeek: Int {
        thisWeeksLogs.count
    }

    // MARK: - Initialization
    init(userId: String, firestoreManager: FirestoreManager = FirebaseService.shared.firestore) {
        self.userId = userId
        self.firestoreManager = firestoreManager
        setupListeners()
        restoreActiveWorkout()
    }

    deinit {
        timerCancellable?.cancel()
        listenerRegistrations.forEach { $0.remove() }
    }

    // MARK: - Data Loading

    private func setupListeners() {
        isLoading = true

        // Listen to workout logs
        let logsResult = firestoreManager.fetchWorkoutLogs(userId: userId)
        listenerRegistrations.append(logsResult.registration)

        logsResult.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] logs in
                self?.isLoading = false
                self?.logs = logs
            }
            .store(in: &cancellables)

        // Listen to personal records
        let prResult = firestoreManager.fetchPersonalRecords(userId: userId)
        listenerRegistrations.append(prResult.registration)

        prResult.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] records in
                self?.personalRecords = records
            }
            .store(in: &cancellables)
    }

    // MARK: - Workout Session

    /// Start a new workout from a template
    func startWorkout(from day: WorkoutDay, program: Program?) {
        let workout = WorkoutLog.from(day: day, program: program, userId: userId)
        activeWorkout = workout
        isWorkoutActive = true
        newPRs = []
        startTimer()
        persistActiveWorkout()

        // Asynchronously fetch history
        Task {
            await fillHistory()
        }
    }

    /// Start a blank workout
    func startBlankWorkout() {
        activeWorkout = WorkoutLog(
            userId: userId,
            dayName: "Quick Workout"
        )
        isWorkoutActive = true
        newPRs = []
        startTimer()
        persistActiveWorkout()
    }

    /// Populate previous performance for the active workout
    private func fillHistory() async {
        guard let workout = activeWorkout else { return }
        var updatedWorkout = workout

        for (i, exercise) in updatedWorkout.exercises.enumerated() {
            do {
                if let history = try await firestoreManager.getLastPerformance(userId: userId, exerciseName: exercise.name) {
                    // Populate sets with history
                    for (j, _) in exercise.completedSets.enumerated() {
                        if j < history.count {
                            updatedWorkout.exercises[i].completedSets[j].previousPerformance = history[j]
                        } else if !history.isEmpty {
                            // If we have more sets than history, use the last known history
                            updatedWorkout.exercises[i].completedSets[j].previousPerformance = history.last
                        }
                    }
                }
            } catch {
                print("Failed to fetch history for \(exercise.name): \(error)")
            }
        }

        // Update on main actor
        activeWorkout = updatedWorkout
        persistActiveWorkout()
    }

    /// Add an exercise to the active workout
    func addExercise(_ exercise: Exercise) {
        guard var workout = activeWorkout else { return }

        let exerciseLog = ExerciseLog.from(exercise: exercise)
        workout.exercises.append(exerciseLog)
        activeWorkout = workout
        persistActiveWorkout()
    }

    /// Update a set in the active workout
    func updateSet(exerciseIndex: Int, setIndex: Int, reps: Int, weight: Double, isCompleted: Bool) {
        guard var workout = activeWorkout else { return }
        guard exerciseIndex < workout.exercises.count,
              setIndex < workout.exercises[exerciseIndex].completedSets.count else { return }

        workout.exercises[exerciseIndex].completedSets[setIndex].actualReps = reps
        workout.exercises[exerciseIndex].completedSets[setIndex].weight = weight
        workout.exercises[exerciseIndex].completedSets[setIndex].isCompleted = isCompleted

        activeWorkout = workout
        persistActiveWorkout()
    }

    /// Add a set to an exercise in the active workout
    func addSet(to exerciseIndex: Int) {
        guard var workout = activeWorkout, exerciseIndex < workout.exercises.count else { return }

        let lastSet = workout.exercises[exerciseIndex].completedSets.last
        let newSet = SetLog(
            setNumber: (lastSet?.setNumber ?? 0) + 1,
            targetReps: lastSet?.targetReps ?? 10,
            targetWeight: lastSet?.targetWeight ?? 0,
            weight: lastSet?.weight ?? 0
        )

        workout.exercises[exerciseIndex].completedSets.append(newSet)
        activeWorkout = workout
        persistActiveWorkout()
    }

    /// Remove a set from an exercise
    func removeSet(from exerciseIndex: Int, at setIndex: Int) {
        guard var workout = activeWorkout,
              exerciseIndex < workout.exercises.count,
              setIndex < workout.exercises[exerciseIndex].completedSets.count else { return }

        workout.exercises[exerciseIndex].completedSets.remove(at: setIndex)

        // Renumber remaining sets
        for i in 0..<workout.exercises[exerciseIndex].completedSets.count {
            workout.exercises[exerciseIndex].completedSets[i].setNumber = i + 1
        }

        activeWorkout = workout
        persistActiveWorkout()
    }

    /// Complete and save the active workout
    func completeWorkout() async {
        guard var workout = activeWorkout, !isLoading else { return }

        stopTimer()

        workout.completedAt = Date()
        workout.duration = workoutTimer

        isLoading = true

        do {
            // Check for PRs using locally cached personal records
            checkForPRs(in: workout)

            // Mark PRs in the workout
            for i in 0..<workout.exercises.count {
                for j in 0..<workout.exercises[i].completedSets.count {
                    if newPRs.contains(workout.exercises[i].name) {
                        workout.exercises[i].completedSets[j].isPR = true
                    }
                }
            }

            // Save new PRs to Firestore
            for exercise in workout.exercises {
                guard let bestSet = exercise.bestSet, bestSet.isCompleted, bestSet.weight > 0 else { continue }
                if newPRs.contains(exercise.name) {
                    let newPR = PersonalRecord(
                        userId: userId,
                        exerciseName: exercise.name,
                        weight: bestSet.weight,
                        reps: bestSet.actualReps,
                        workoutLogId: workout.id
                    )
                    try await firestoreManager.savePersonalRecord(newPR)
                }
            }

            // Save the workout
            try await firestoreManager.saveWorkoutLog(workout)

            // Award XP for workout completion
            if let levelVM = levelViewModel {
                await levelVM.awardWorkoutXP(hasPRs: !newPRs.isEmpty)
            }

            // Reset state
            activeWorkout = nil
            isWorkoutActive = false
            workoutTimer = 0
            clearPersistedWorkout()

        } catch {
            handleError(error)
        }

        isLoading = false
    }

    /// Discard the active workout
    func discardWorkout() {
        stopTimer()
        activeWorkout = nil
        isWorkoutActive = false
        workoutTimer = 0
        newPRs = []
        clearPersistedWorkout()
    }

    /// Refresh timer display (call when view appears after backgrounding)
    func refreshTimer() {
        updateTimerFromStartTime()
    }

    // MARK: - Log Operations

    /// Delete a workout log
    func deleteLog(_ log: WorkoutLog) async {
        isLoading = true

        do {
            try await firestoreManager.deleteWorkoutLog(id: log.id)
        } catch {
            handleError(error)
        }

        isLoading = false
    }

    /// Delete logs at index set
    func deleteLogs(at indexSet: IndexSet) async {
        let logsToDelete = indexSet.map { logs[$0] }

        for log in logsToDelete {
            await deleteLog(log)
        }
    }

    // MARK: - Personal Records

    /// Get PR for a specific exercise
    func getPR(for exerciseName: String) -> PersonalRecord? {
        personalRecords.first { $0.exerciseName == exerciseName }
    }

    /// Check for new PRs using locally cached personal records (eliminates N+1 queries)
    private func checkForPRs(in workout: WorkoutLog) {
        for exercise in workout.exercises {
            guard let bestSet = exercise.bestSet, bestSet.isCompleted, bestSet.weight > 0 else { continue }

            let existingPR = personalRecords.first { $0.exerciseName == exercise.name }

            let isNewPR: Bool
            if let existing = existingPR {
                isNewPR = bestSet.weight > existing.weight ||
                    (bestSet.weight == existing.weight && bestSet.actualReps > existing.reps)
            } else {
                isNewPR = true
            }

            if isNewPR {
                newPRs.append(exercise.name)
            }
        }
    }

    // MARK: - Workout Persistence

    /// Save active workout state to UserDefaults for crash resilience
    private func persistActiveWorkout() {
        guard let workout = activeWorkout else {
            UserDefaults.standard.removeObject(forKey: Self.activeWorkoutKey)
            UserDefaults.standard.removeObject(forKey: Self.workoutStartTimeKey)
            return
        }

        if let data = try? JSONEncoder().encode(workout) {
            UserDefaults.standard.set(data, forKey: Self.activeWorkoutKey)
        }
        if let startTime = workoutStartTime {
            UserDefaults.standard.set(startTime, forKey: Self.workoutStartTimeKey)
        }
    }

    /// Clear persisted workout state
    private func clearPersistedWorkout() {
        UserDefaults.standard.removeObject(forKey: Self.activeWorkoutKey)
        UserDefaults.standard.removeObject(forKey: Self.workoutStartTimeKey)
    }

    /// Restore active workout after app crash or restart
    private func restoreActiveWorkout() {
        guard let data = UserDefaults.standard.data(forKey: Self.activeWorkoutKey),
              let workout = try? JSONDecoder().decode(WorkoutLog.self, from: data) else {
            return
        }

        activeWorkout = workout
        isWorkoutActive = true

        // Restore start time and resume timer
        if let startTime = UserDefaults.standard.object(forKey: Self.workoutStartTimeKey) as? Date {
            workoutStartTime = startTime
            workoutTimer = Date().timeIntervalSince(startTime)
            resumeTimer()
        }
    }

    // MARK: - Timer

    private func startTimer() {
        workoutStartTime = Date()
        workoutTimer = 0
        resumeTimer()
    }

    /// Resume the timer tick without resetting start time (used after crash restore)
    private func resumeTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.updateTimerFromStartTime()
            }
    }

    private func updateTimerFromStartTime() {
        guard let startTime = workoutStartTime else { return }
        workoutTimer = Date().timeIntervalSince(startTime)
    }

    private func stopTimer() {
        // Calculate final duration before stopping
        if let startTime = workoutStartTime {
            workoutTimer = Date().timeIntervalSince(startTime)
        }
        timerCancellable?.cancel()
        timerCancellable = nil
        workoutStartTime = nil
    }
}
