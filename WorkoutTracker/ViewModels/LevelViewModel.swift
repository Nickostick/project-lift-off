import Foundation
import Combine
import FirebaseFirestore

/// ViewModel for managing user level state and progression
@MainActor
final class LevelViewModel: ObservableObject, ViewModelErrorHandling {

    // MARK: - Published Properties
    @Published var userLevel: UserLevel?
    @Published var isLoading = false
    @Published var showError = false
    @Published var errorMessage = ""
    @Published var showLevelUpCelebration = false
    @Published var levelUpPreviousLevel: Int?

    // MARK: - Dependencies
    private let firestoreManager: FirestoreManager
    private let userId: String
    private var cancellables = Set<AnyCancellable>()
    private var listenerRegistration: ListenerRegistration?

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

    deinit {
        listenerRegistration?.remove()
    }

    // MARK: - Data Loading

    private func setupListener() {
        isLoading = true

        let result = firestoreManager.fetchUserLevel(userId: userId)
        listenerRegistration = result.registration

        result.publisher
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
        let xpAmount = UserLevel.workoutXP(hasPRs: hasPRs)

        do {
            let (updatedLevel, didLevelUp, previousLevel) = try await firestoreManager.awardXP(
                userId: userId,
                xpAmount: xpAmount,
                currentLevel: userLevel
            )

            userLevel = updatedLevel

            if didLevelUp, let previous = previousLevel {
                levelUpPreviousLevel = previous
                showLevelUpCelebration = true
            }

        } catch {
            handleError(error)
        }
    }

    /// Dismiss level up celebration
    func dismissLevelUp() {
        showLevelUpCelebration = false
        levelUpPreviousLevel = nil
    }
}
