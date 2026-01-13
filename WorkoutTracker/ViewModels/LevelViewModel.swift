import Foundation
import Combine

/// ViewModel for managing user level state and progression
@MainActor
final class LevelViewModel: ObservableObject {

    // MARK: - Published Properties
    @Published var userLevel: UserLevel?
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var pendingLevelUp: LevelUpEvent?
    @Published var showLevelUpCelebration = false

    // MARK: - Dependencies
    private let firestoreManager: FirestoreManager
    private let userId: String
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Computed Properties
    var currentLevel: Int {
        userLevel?.currentLevel ?? 1
    }

    var progressToNextLevel: Double {
        userLevel?.progressToNextLevel ?? 0.0
    }

    var formattedProgress: String {
        userLevel?.formattedProgress ?? "0/150 XP"
    }

    // MARK: - Initialization
    init(userId: String, firestoreManager: FirestoreManager = FirebaseService.shared.firestore) {
        self.userId = userId
        self.firestoreManager = firestoreManager
        setupListener()
    }

    // MARK: - Data Loading

    private func setupListener() {
        isLoading = true

        firestoreManager.fetchUserLevel(userId: userId)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                self?.isLoading = false
                if case .failure(let error) = completion {
                    self?.handleError(error)
                }
            } receiveValue: { [weak self] level in
                self?.isLoading = false
                if let level = level {
                    self?.userLevel = level
                } else {
                    // Initialize for new user
                    Task {
                        await self?.initializeUserLevel()
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func initializeUserLevel() async {
        do {
            let newLevel = try await firestoreManager.initializeUserLevel(userId: userId)
            userLevel = newLevel
        } catch {
            handleError(error)
        }
    }

    // MARK: - XP Award

    /// Award XP to the user (called after workout completion)
    func awardWorkoutXP(hasPRs: Bool) async {
        let xpAmount = LevelingService.calculateWorkoutXP(hasPRs: hasPRs)

        do {
            let (updatedLevel, didLevelUp, previousLevel) = try await firestoreManager.awardXP(
                userId: userId,
                xpAmount: xpAmount,
                currentLevel: userLevel
            )

            // Update local state
            userLevel = updatedLevel

            // Trigger celebration if leveled up
            if didLevelUp, let previous = previousLevel {
                pendingLevelUp = LevelUpEvent(
                    previousLevel: previous,
                    newLevel: updatedLevel.currentLevel,
                    timestamp: Date()
                )
                showLevelUpCelebration = true
            }

        } catch {
            handleError(error)
        }
    }

    /// Dismiss level up celebration
    func dismissLevelUp() {
        showLevelUpCelebration = false
        pendingLevelUp = nil
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        self.errorMessage = error.localizedDescription
        self.showError = true
        print("❌ LevelViewModel error: \(error)")
    }
}
