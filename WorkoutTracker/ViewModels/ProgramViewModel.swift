import Foundation
import Combine
import FirebaseFirestore

/// ViewModel for managing workout program templates
@MainActor
final class ProgramViewModel: ObservableObject, ViewModelErrorHandling {

    // MARK: - Published Properties
    @Published var programs: [Program] = []
    @Published var selectedProgram: Program?
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var searchText = ""

    // MARK: - Dependencies
    private let firestoreManager: FirestoreManager
    private let userId: String
    private var cancellables = Set<AnyCancellable>()
    private var listenerRegistration: ListenerRegistration?

    // MARK: - Computed Properties
    var filteredPrograms: [Program] {
        if searchText.isEmpty {
            return programs
        }
        return programs.filter { 
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.description.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    // MARK: - Initialization
    init(userId: String, firestoreManager: FirestoreManager = FirebaseService.shared.firestore) {
        self.userId = userId
        self.firestoreManager = firestoreManager
        setupListeners()
    }

    deinit {
        listenerRegistration?.remove()
    }

    // MARK: - Data Loading

    private func setupListeners() {
        isLoading = true

        let result = firestoreManager.fetchPrograms(userId: userId)
        listenerRegistration = result.registration

        result.publisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] programs in
                self?.isLoading = false
                self?.programs = programs
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Program CRUD Operations
    
    /// Create a new program
    func createProgram(name: String, description: String = "") async {
        let program = Program(
            userId: userId,
            name: name,
            description: description
        )
        
        await saveProgram(program)
    }
    
    /// Save a program (create or update)
    func saveProgram(_ program: Program) async {
        isLoading = true
        
        do {
            try await firestoreManager.saveProgram(program)
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Delete a program
    func deleteProgram(_ program: Program) async {
        isLoading = true
        
        do {
            try await firestoreManager.deleteProgram(id: program.id)
        } catch {
            handleError(error)
        }
        
        isLoading = false
    }
    
    /// Delete programs at index set (for list deletion)
    func deletePrograms(at indexSet: IndexSet) async {
        let programsToDelete = indexSet.map { filteredPrograms[$0] }
        
        for program in programsToDelete {
            await deleteProgram(program)
        }
    }
    
    /// Copy a program
    func copyProgram(_ program: Program) async {
        let copiedProgram = program.copy(forUser: userId)
        var renamedProgram = copiedProgram
        renamedProgram.name = "\(program.name) (Copy)"
        
        await saveProgram(renamedProgram)
    }
    
    // MARK: - Day Operations
    
    /// Add a day to a program
    func addDay(to program: Program, name: String, notes: String = "") async {
        var updatedProgram = program
        let newDay = WorkoutDay(
            name: name,
            order: program.days.count,
            notes: notes
        )
        updatedProgram.days.append(newDay)
        
        await saveProgram(updatedProgram)
    }
    
    /// Update a day in a program
    func updateDay(in program: Program, day: WorkoutDay) async {
        var updatedProgram = program
        if let index = updatedProgram.days.firstIndex(where: { $0.id == day.id }) {
            updatedProgram.days[index] = day
            await saveProgram(updatedProgram)
        }
    }
    
    /// Delete a day from a program
    func deleteDay(from program: Program, day: WorkoutDay) async {
        var updatedProgram = program
        updatedProgram.days.removeAll { $0.id == day.id }
        
        // Reorder remaining days
        for i in 0..<updatedProgram.days.count {
            updatedProgram.days[i].order = i
        }
        
        await saveProgram(updatedProgram)
    }
    
    /// Reorder days in a program
    func moveDays(in program: Program, from source: IndexSet, to destination: Int) async {
        var updatedProgram = program
        updatedProgram.days.move(fromOffsets: source, toOffset: destination)
        
        // Update order values
        for i in 0..<updatedProgram.days.count {
            updatedProgram.days[i].order = i
        }
        
        await saveProgram(updatedProgram)
    }
    
    // MARK: - Exercise Operations
    
    /// Add an exercise to a day
    func addExercise(to program: Program, dayId: String, exercise: Exercise) async {
        var updatedProgram = program
        if let dayIndex = updatedProgram.days.firstIndex(where: { $0.id == dayId }) {
            var newExercise = exercise
            newExercise.order = updatedProgram.days[dayIndex].exercises.count
            updatedProgram.days[dayIndex].exercises.append(newExercise)
            await saveProgram(updatedProgram)
        }
    }
    
    /// Update an exercise in a day
    func updateExercise(in program: Program, dayId: String, exercise: Exercise) async {
        var updatedProgram = program
        if let dayIndex = updatedProgram.days.firstIndex(where: { $0.id == dayId }),
           let exerciseIndex = updatedProgram.days[dayIndex].exercises.firstIndex(where: { $0.id == exercise.id }) {
            updatedProgram.days[dayIndex].exercises[exerciseIndex] = exercise
            await saveProgram(updatedProgram)
        }
    }
    
    /// Delete an exercise from a day
    func deleteExercise(from program: Program, dayId: String, exercise: Exercise) async {
        var updatedProgram = program
        if let dayIndex = updatedProgram.days.firstIndex(where: { $0.id == dayId }) {
            updatedProgram.days[dayIndex].exercises.removeAll { $0.id == exercise.id }
            
            // Reorder remaining exercises
            for i in 0..<updatedProgram.days[dayIndex].exercises.count {
                updatedProgram.days[dayIndex].exercises[i].order = i
            }
            
            await saveProgram(updatedProgram)
        }
    }
    
    /// Reorder exercises in a day
    func moveExercises(in program: Program, dayId: String, from source: IndexSet, to destination: Int) async {
        var updatedProgram = program
        if let dayIndex = updatedProgram.days.firstIndex(where: { $0.id == dayId }) {
            updatedProgram.days[dayIndex].exercises.move(fromOffsets: source, toOffset: destination)
            
            // Update order values
            for i in 0..<updatedProgram.days[dayIndex].exercises.count {
                updatedProgram.days[dayIndex].exercises[i].order = i
            }
            
            await saveProgram(updatedProgram)
        }
    }
    
    // MARK: - Sharing
    
    /// Generate share data for a program
    func getShareItems(for program: Program) -> [Any] {
        var items: [Any] = []
        
        // Add text description
        var description = "Check out my workout program: \(program.name)\n\n"
        for day in program.days {
            description += "📅 \(day.name)\n"
            for exercise in day.exercises {
                description += "  • \(exercise.name): \(exercise.formattedTarget)\n"
            }
            description += "\n"
        }
        items.append(description)
        
        // Add URL if available
        if let url = program.shareURL {
            items.append(url)
        }
        
        return items
    }
    
}
