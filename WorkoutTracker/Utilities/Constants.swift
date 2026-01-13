import Foundation

/// App-wide constants and configuration values
enum Constants {
    /// Firebase collection names
    enum Collections {
        static let programs = "programs"
        static let workoutLogs = "workoutLogs"
        static let personalRecords = "personalRecords"
        static let users = "users"
        static let userLevels = "userLevels"
    }
    
    /// UserDefaults keys
    enum UserDefaultsKeys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let preferredWeightUnit = "preferredWeightUnit"
        static let enableNotifications = "enableNotifications"
        static let reminderDays = "reminderDays"
        static let reminderTime = "reminderTime"
        static let lastSyncDate = "lastSyncDate"
    }
    
    /// App configuration
    enum App {
        static let bundleId = "com.workout.tracker"
        static let appName = "Workout Tracker"
        static let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    
    /// UI Constants
    enum UI {
        static let cornerRadius: CGFloat = 12
        static let cardPadding: CGFloat = 16
        static let animationDuration: Double = 0.3
    }
    
    /// Default values
    enum Defaults {
        static let defaultSets = 3
        static let defaultReps = 10
        static let defaultRestSeconds = 60
        static let defaultWeightUnit = WeightUnit.pounds
    }

    /// XP and leveling constants
    enum XP {
        static let baseWorkoutXP = 100
        static let prMultiplier = 2.0
        static let levelBaseXP = 100.0
        static let levelExponent = 1.5
    }
}

/// Common exercise names for suggestions
enum CommonExercises {
    static let chest = [
        "Bench Press",
        "Incline Bench Press",
        "Decline Bench Press",
        "Dumbbell Fly",
        "Cable Crossover",
        "Push-Up",
        "Chest Dip"
    ]
    
    static let back = [
        "Deadlift",
        "Bent Over Row",
        "Pull-Up",
        "Lat Pulldown",
        "Seated Cable Row",
        "T-Bar Row",
        "Face Pull"
    ]
    
    static let shoulders = [
        "Overhead Press",
        "Lateral Raise",
        "Front Raise",
        "Rear Delt Fly",
        "Arnold Press",
        "Shrugs"
    ]
    
    static let arms = [
        "Bicep Curl",
        "Hammer Curl",
        "Tricep Pushdown",
        "Skull Crusher",
        "Preacher Curl",
        "Tricep Dip",
        "Concentration Curl"
    ]
    
    static let legs = [
        "Squat",
        "Leg Press",
        "Lunges",
        "Leg Curl",
        "Leg Extension",
        "Calf Raise",
        "Romanian Deadlift",
        "Hip Thrust"
    ]
    
    static let core = [
        "Plank",
        "Crunch",
        "Russian Twist",
        "Leg Raise",
        "Ab Wheel Rollout",
        "Cable Crunch"
    ]
    
    static var all: [String] {
        chest + back + shoulders + arms + legs + core
    }
}
