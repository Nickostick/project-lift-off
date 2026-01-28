import Foundation

/// Represents a user's leveling progress
struct UserLevel: Identifiable, Codable, Hashable {
    var id: String
    var userId: String
    var currentLevel: Int
    var currentXP: Int
    var totalXP: Int
    var lastLevelUpDate: Date?
    var updatedAt: Date

    init(
        id: String = UUID().uuidString,
        userId: String,
        currentLevel: Int = 1,
        currentXP: Int = 0,
        totalXP: Int = 0,
        lastLevelUpDate: Date? = nil,
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.userId = userId
        self.currentLevel = currentLevel
        self.currentXP = currentXP
        self.totalXP = totalXP
        self.lastLevelUpDate = lastLevelUpDate
        self.updatedAt = updatedAt
    }

    // MARK: - Computed Properties

    /// Calculate XP required for a specific level using formula: 100 × (1.5^level)
    static func xpRequiredForLevel(_ level: Int) -> Int {
        return Int(100.0 * pow(1.5, Double(level)))
    }

    /// XP required to reach next level
    var xpForNextLevel: Int {
        Self.xpRequiredForLevel(currentLevel)
    }

    /// Progress percentage (0.0 to 1.0) toward next level
    var progressToNextLevel: Double {
        guard xpForNextLevel > 0 else { return 0.0 }
        return Double(currentXP) / Double(xpForNextLevel)
    }

    /// Formatted XP progress string (e.g., "450/1000 XP")
    var formattedProgress: String {
        "\(currentXP)/\(xpForNextLevel) XP"
    }

    // MARK: - XP Calculations

    /// Calculate XP earned for completing a workout
    static func workoutXP(hasPRs: Bool) -> Int {
        let baseXP = Constants.XP.baseWorkoutXP
        return hasPRs ? Int(Double(baseXP) * Constants.XP.prMultiplier) : baseXP
    }

    /// Add XP and calculate new level state
    /// Returns: (newLevel, newCurrentXP, newTotalXP, leveledUp)
    static func addXP(
        currentLevel: Int,
        currentXP: Int,
        totalXP: Int,
        earnedXP: Int
    ) -> (newLevel: Int, newCurrentXP: Int, newTotalXP: Int, leveledUp: Bool) {
        var level = currentLevel
        var xp = currentXP + earnedXP
        let newTotalXP = totalXP + earnedXP
        var leveledUp = false

        // Check for level ups (could level up multiple times)
        while xp >= xpRequiredForLevel(level) {
            xp -= xpRequiredForLevel(level)
            level += 1
            leveledUp = true
        }

        return (level, xp, newTotalXP, leveledUp)
    }
}

// MARK: - Firestore Conversion
extension UserLevel {
    /// Convert model to Firestore-compatible dictionary
    var firestoreData: [String: Any] {
        var data: [String: Any] = [
            "id": id,
            "userId": userId,
            "currentLevel": currentLevel,
            "currentXP": currentXP,
            "totalXP": totalXP,
            "updatedAt": updatedAt
        ]

        if let lastLevelUpDate = lastLevelUpDate {
            data["lastLevelUpDate"] = lastLevelUpDate
        }

        return data
    }

    /// Initialize model from Firestore dictionary
    init?(from data: [String: Any]) {
        guard let id = data["id"] as? String,
              let userId = data["userId"] as? String,
              let currentLevel = data["currentLevel"] as? Int,
              let currentXP = data["currentXP"] as? Int,
              let totalXP = data["totalXP"] as? Int else {
            return nil
        }

        self.id = id
        self.userId = userId
        self.currentLevel = currentLevel
        self.currentXP = currentXP
        self.totalXP = totalXP
        self.lastLevelUpDate = data["lastLevelUpDate"] as? Date
        self.updatedAt = data["updatedAt"] as? Date ?? Date()
    }
}
