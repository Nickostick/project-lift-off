import Foundation

/// Service for calculating XP and managing level progression
final class LevelingService {

    // MARK: - XP Calculation

    /// Calculate XP earned for a workout
    /// - Parameters:
    ///   - hasPRs: Whether the workout contained any personal records
    /// - Returns: XP amount earned
    static func calculateWorkoutXP(hasPRs: Bool) -> Int {
        let baseXP = Constants.XP.baseWorkoutXP
        if hasPRs {
            return Int(Double(baseXP) * Constants.XP.prMultiplier)
        }
        return baseXP
    }

    // MARK: - Level Progression

    /// Calculate new level state after adding XP
    /// - Parameters:
    ///   - currentLevel: Current user level
    ///   - currentXP: Current XP within level
    ///   - totalXP: Total lifetime XP
    ///   - earnedXP: XP to add
    /// - Returns: Tuple of (newLevel, newCurrentXP, newTotalXP, leveledUp)
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
        while xp >= UserLevel.xpRequiredForLevel(level) {
            xp -= UserLevel.xpRequiredForLevel(level)
            level += 1
            leveledUp = true
        }

        return (level, xp, newTotalXP, leveledUp)
    }

    /// Get level from total XP (for retroactive calculations if needed)
    static func calculateLevelFromTotalXP(_ totalXP: Int) -> (level: Int, currentXP: Int) {
        var level = 1
        var remainingXP = totalXP

        while remainingXP >= UserLevel.xpRequiredForLevel(level) {
            remainingXP -= UserLevel.xpRequiredForLevel(level)
            level += 1
        }

        return (level, remainingXP)
    }
}
