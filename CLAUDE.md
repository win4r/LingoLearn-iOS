# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build and Run Commands

This is a SwiftUI iOS application using Xcode.

**Build:**
```bash
xcodebuild -project LingoLearn.xcodeproj -scheme LingoLearn -destination 'platform=iOS Simulator,name=iPhone 17' build
```

**Run Tests:**
```bash
xcodebuild -project LingoLearn.xcodeproj -scheme LingoLearn -destination 'platform=iOS Simulator,name=iPhone 17' test
```

## Project Configuration

- **Platform:** iOS 26.0+
- **Swift Version:** 5.0
- **UI Framework:** SwiftUI
- **Data Persistence:** SwiftData
- **Charts:** Swift Charts
- **Testing:** Swift Testing framework for unit tests, XCTest for UI tests

## Architecture

### MVVM + Repository Pattern

```
Views (SwiftUI) → ViewModels (@Observable) → Services/Repositories → SwiftData (ModelContext)
```

### Directory Structure

```
LingoLearn/
├── LingoLearnApp.swift          # App entry, ModelContainer setup
├── ContentView.swift            # TabView navigation (5 tabs)
│
├── Models/                      # SwiftData @Model entities
│   ├── Word.swift               # Core vocabulary model + SM-2 fields
│   ├── StudySession.swift       # Learning session records
│   ├── DailyProgress.swift      # Daily statistics
│   ├── UserStats.swift          # Global user statistics
│   └── UserSettings.swift       # App settings
│
├── Core/
│   ├── Theme/AppColors.swift    # Color definitions (#0EA5E9, #14B8A6)
│   ├── Extensions/              # Date, Color, View extensions
│   ├── Utilities/HapticManager.swift
│   └── Components/              # RingProgressView, FlameStreakView, etc.
│
├── Services/
│   ├── SM2Service.swift         # Spaced repetition algorithm
│   ├── SpeechService.swift      # AVSpeechSynthesizer TTS
│   ├── DataSeederService.swift  # First-launch word data loading
│   ├── AchievementService.swift # Achievement checking
│   └── NotificationService.swift # Local notifications
│
├── Features/
│   ├── Home/                    # Dashboard with progress ring
│   ├── Learning/                # Flashcard study (3D flip, swipe gestures)
│   ├── Practice/                # Tests (multiple choice, fill-in, listening)
│   ├── Progress/                # Charts (line, heatmap, pie) + achievements
│   └── Settings/                # User preferences
│
└── Resources/Words/
    ├── cet4_words.json          # 300 CET-4 vocabulary
    └── cet6_words.json          # 200 CET-6 vocabulary
```

### Key Models

**Word** - Vocabulary with SM-2 spaced repetition fields:
- `easeFactor`, `interval`, `repetitions`, `nextReviewDate`
- `masteryLevel`: `.new`, `.learning`, `.reviewing`, `.mastered`

**UserSettings** - App configuration:
- `dailyGoal` (10-100), `reminderEnabled`, `appearanceMode`

### SwiftData Predicate Notes

When using `#Predicate` with enums, capture values in local variables:
```swift
let mastered = MasteryLevel.mastered
let predicate = #Predicate<Word> { $0.masteryLevel == mastered }
```

### Key Features

1. **SM-2 Algorithm** (`Services/SM2Service.swift`) - Spaced repetition scheduling
2. **Flashcard Animations** (`Features/Learning/Components/FlashcardItem.swift`) - 3D flip, swipe gestures
3. **Swift Charts** (`Features/Progress/Components/`) - Line chart, calendar heatmap, pie chart
4. **Achievement System** (`Services/AchievementService.swift`) - 8 achievement types
