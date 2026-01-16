# WorkoutTracker - Claude Context

## Project Overview
iOS workout tracking app with progressive overload tracking, workout programs, personal records, and gamification. Built with SwiftUI + Firebase.

**Bundle ID:** com.nicholasprijic.workouttracker
**Team ID:** 35Q5DRWA8G
**Deployment:** TestFlight via App Store Connect

## Tech Stack
- **Frontend:** SwiftUI (iOS 17+)
- **Backend:** Firebase (Auth, Firestore)
- **Architecture:** MVVM with Combine for reactive data flow
- **State Management:** @StateObject, @ObservedObject, @Published

## Key Architecture Patterns

### ViewModels
- Use `PassthroughSubject` + `AnyPublisher` for Firestore real-time listeners
- Store Combine cancellables in `Set<AnyCancellable>`
- Weak references between ViewModels to prevent retain cycles (e.g., `WorkoutLogViewModel.levelViewModel`)

### Firestore Integration
- All operations in `FirestoreManager.swift`
- Convert Firestore Timestamps to Date in fetch methods
- Models provide `firestoreData` computed property and `init?(from: [String: Any])`
- Real-time listeners use `addSnapshotListener` with error handling

### Design System
- **Theme:** Premium dark (#000000 background, #1A1A1A cards)
- **Colors:** Defined in `AppTheme` (primaryBlue, neonGreen, energyOrange, vibrantPurple)
- **Typography:** SF Pro with specific sizes and weights per component type
- **Spacing:** Consistent 12-20pt padding, 16pt card corner radius

## Project Structure
```
WorkoutTracker/
├── Models/           # Data models (Codable + Firestore conversion)
├── ViewModels/       # Business logic + state management
├── Views/            # SwiftUI views (organized by feature)
├── Components/       # Reusable UI components
├── Services/         # Firebase, notifications, utilities
└── Utilities/        # Constants, extensions, themes
```

## Core Data Models
- **Program:** Workout programs with multiple WorkoutDay entries
- **WorkoutLog:** Completed workout with exercises and sets
- **PersonalRecord:** Best weight × reps for each exercise
- **UserLevel:** Current level, XP progress (leveling system)

## Critical Services
- **FirestoreManager:** All database operations, single source of truth
- **LevelingService:** Pure XP calculation functions (100 × 1.5^level formula)
- **NotificationManager:** Workout reminders

## Recent Major Features

### Leveling System (Jan 2026)
- **XP Awards:** 100 XP per workout, 200 XP with PRs (2x multiplier)
- **Formula:** Level N requires 100 × (1.5^N) XP
- **UI:** LevelProgressCard on HomeView, LevelUpView celebration with confetti
- **Integration:** WorkoutLogViewModel → LevelViewModel.awardXP() after workout completion
- **Files:** UserLevel.swift, LevelViewModel.swift, LevelingService.swift, LevelProgressCard.swift, LevelUpView.swift

## Development Workflow

### Building & Deployment
```bash
# Archive
xcodebuild archive -scheme WorkoutTracker -archivePath build/WorkoutTracker.xcarchive

# Export (requires ExportOptions.plist with teamID: 35Q5DRWA8G)
xcodebuild -exportArchive -archivePath build/WorkoutTracker.xcarchive \
  -exportPath build -exportOptionsPlist ExportOptions.plist

# Upload to TestFlight (set APPLE_ID and APP_SPECIFIC_PASSWORD as environment variables)
xcrun altool --upload-app -f build/WorkoutTracker.ipa -t ios \
  -u "$APPLE_ID" -p "$APP_SPECIFIC_PASSWORD"
```

**Note:** Store credentials in your shell profile (~/.zshrc or ~/.bash_profile):
```bash
export APPLE_ID="your-apple-id@email.com"
export APP_SPECIFIC_PASSWORD="your-app-specific-password"
```

### Git Commit Style
```
Add/Update/Fix [feature name]

[2-3 sentence description of changes]

Key changes:
- Bullet points of main modifications
- New files or integrations

Technical notes if applicable
```

## Common Patterns

### Adding New Features
1. Create data model in `/Models` with Firestore conversion
2. Add Firestore operations to `FirestoreManager`
3. Create ViewModel with Combine publishers
4. Build UI components in `/Components`
5. Integrate into feature views in `/Views`
6. Update `Constants.swift` for new collections/config

### State Flow
```
User Action → ViewModel Method → FirestoreManager Operation
   ↓                                      ↓
UI Update ← Published Property ← Real-time Listener
```

## Known Conventions
- Avoid over-engineering: only add features explicitly requested
- No unused parameter renames or backwards-compatibility hacks
- Use dedicated tools (Read/Edit/Write) instead of bash for file ops
- Always read files before modifying them
- Dark theme colors: use hex values from AppTheme, never hardcode

## Firestore Collections
- `programs` - User workout programs
- `workoutLogs` - Completed workouts
- `personalRecords` - Best lifts per exercise
- `userLevels` - XP and level data

## Issues & Fixes Log
*Add issues encountered and their solutions here as they arise*

---
**Last Updated:** 2026-01-12
**Current Version:** 1.0 (Build on TestFlight)
