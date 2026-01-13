import Foundation

/// Represents a level-up event for display in celebration view
struct LevelUpEvent {
    let previousLevel: Int
    let newLevel: Int
    let timestamp: Date

    /// Number of levels gained
    var levelGain: Int {
        newLevel - previousLevel
    }
}
