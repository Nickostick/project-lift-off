import Foundation
import Combine

/// ViewModel for workout logging and log history
@MainActor
final class WorkoutLogViewModel: ObservableObject {
    
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
    private var timerCancellable: AnyCancellable?
    private var workoutStartTime: Date? // Store start time for accurate duration
    
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
    }
    
    deinit {
        timerCancellable?.cancel()
    }
    
    // MARK: - Data Loading
    
    private func setupListeners() {
        isLoading = true
        
        // Listen to workout logs
        firestoreManager.fetchWorkoutLogs(userId: userId)
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
        firestoreManager.fetchPersonalRecords(userId: userId)
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
    }
    
    /// Add an exercise to the active workout
    func addExercise(_ exercise: Exercise) {
        guard var workout = activeWorkout else { return }
        
        let exerciseLog = ExerciseLog.from(exercise: exercise)
        workout.exercises.append(exerciseLog)
        activeWorkout = workout
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
    }
    
    /// Complete and save the active workout
    func completeWorkout() async {
        guard var workout = activeWorkout else { return }
        
        stopTimer()
        
        workout.completedAt = Date()
        workout.duration = workoutTimer
        
        isLoading = true
        
        do {
            // Check for PRs
            await checkForPRs(in: workout)
            
            // Mark PRs in the workout
            for i in 0..<workout.exercises.count {
                for j in 0..<workout.exercises[i].completedSets.count {
                    if newPRs.contains(workout.exercises[i].name) {
                        workout.exercises[i].completedSets[j].isPR = true
                    }
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
    
    /// Check for new PRs in a workout
    private func checkForPRs(in workout: WorkoutLog) async {
        for exercise in workout.exercises {
            guard let bestSet = exercise.bestSet, bestSet.isCompleted, bestSet.weight > 0 else { continue }
            
            do {
                let isNewPR = try await firestoreManager.checkAndUpdatePR(
                    userId: userId,
                    exerciseName: exercise.name,
                    weight: bestSet.weight,
                    reps: bestSet.actualReps,
                    workoutLogId: workout.id
                )
                
                if isNewPR {
                    newPRs.append(exercise.name)
                }
            } catch {
                print("Failed to check PR for \(exercise.name): \(error)")
            }
        }
    }
    
    // MARK: - Timer

    private func startTimer() {
        workoutStartTime = Date()
        workoutTimer = 0

        // Timer updates the display every second by recalculating from start time
        // This ensures accuracy even if app is backgrounded
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
    
    // MARK: - Error Handling
    
    private func handleError(_ error: Error) {
        self.errorMessage = error.localizedDescription
        self.showError = true
        print("❌ WorkoutLogViewModel error: \(error)")
    }
}
