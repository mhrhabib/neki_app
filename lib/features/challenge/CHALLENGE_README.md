# Beat Satan Challenge System 🎯

## Overview
The Challenge system enables users to build consistent habits by committing to 7, 14, or 21-day challenges. Each day they complete earns them points, and missing a day resets the challenge.

## Architecture

### Domain Layer (`features/challenge/domain/`)
- **`entities/challenge_entity.dart`**: Core challenge model with business logic
  - Duration tracking (7/14/21 days)
  - Progress calculation
  - Completion validation
  - Expiry detection

- **`repositories/challenge_repository.dart`**: Abstract repository interface

### Data Layer (`features/challenge/data/`)
- **`models/challenge_model.dart`**: JSON serializable challenge model extending entity
- **`repositories/challenge_repository_impl.dart`**: SharedPreferences-based persistence

### Presentation Layer (`features/challenge/presentation/`)
- **`cubit/challenge_cubit.dart`**: State management
- **`cubit/challenge_state.dart`**: Challenge states (Initial, Loading, Loaded, Error, DayCompleted, FullyCompleted)
- **`screens/goal_selection_screen.dart`**: Choose challenge duration (7/14/21 days)
- **`screens/habit_building_screen.dart`**: Daily challenge tracking and completion
- **`widgets/challenge_progress_widget.dart`**: Visual progress indicator

## Features

### Challenge Creation
- **3 Difficulty Levels**:
  - 🌱 Beginner: 7 days → 70 points
  - 🔥 Intermediate: 14 days → 150 points
  - 💎 Advanced: 21 days → 250 points

### Daily Tracking
- Complete one task per day
- Progress visualization with percentage
- Streak counter
- Remaining days display

### Points Integration
- Points distributed daily on completion
- Formula: `pointsPerDay = totalRewardPoints / durationDays`
- Points awarded through `PointsRepository`

### Challenge Expiry
- Automatically detects missed days
- Challenge fails if a day is skipped
- User must start fresh after failure

## Usage

### Starting a Challenge
```dart
context.read<ChallengeCubit>().startChallenge(
  durationDays: 7,
  rewardPoints: 70,
  challengeType: 'beat_satan',
);
```

### Completing Today's Task
```dart
context.read<ChallengeCubit>().completeTodayChallenge();
```

### Loading Active Challenge
```dart
context.read<ChallengeCubit>().loadChallenge();
```

### Checking Challenge Status
```dart
BlocBuilder<ChallengeCubit, ChallengeState>(
  builder: (context, state) {
    if (state is ChallengeLoaded) {
      if (state.hasActiveChallenge) {
        // Show active challenge UI
      } else {
        // Show start challenge button
      }
    }
  },
)
```

## Navigation Routes

- `/goal-selection` → Choose challenge duration
- `/habit-building` → Daily challenge screen
- Home dashboard → Challenge card (start or continue)

## Persistence

Challenges are stored in SharedPreferences with key `'active_challenge'`:
```json
{
  "durationDays": 7,
  "rewardPoints": 70,
  "startDate": "2025-12-16T10:30:00.000Z",
  "completedDays": 3,
  "status": "active",
  "challengeType": "beat_satan"
}
```

## Islamic UX Elements

✅ **Intent-Based**: Focuses on consistency and patience
✅ **Positive Reinforcement**: "Alhamdulillah!" on completion
✅ **Quranic Motivation**: "Indeed, Allah is with the patient" (2:153)
✅ **No Punishment**: Encouragement over shame
✅ **Growth Mindset**: Start fresh after failure

## Dependency Injection

Registered in `core/di/set_up_di.dart`:
```dart
// Repository
getIt.registerLazySingleton<ChallengeRepository>(
  () => ChallengeRepositoryImpl(getIt<SharedPreferences>())
);

// Cubit
getIt.registerFactory<ChallengeCubit>(
  () => ChallengeCubit(
    getIt<ChallengeRepository>(),
    getIt<PointsRepository>(),
  ),
);
```

## Future Enhancements

- [ ] Multiple concurrent challenges
- [ ] Challenge history and stats
- [ ] Social sharing of achievements
- [ ] Custom challenge types
- [ ] Missed day recovery (1 grace day)
- [ ] Push notifications for daily reminders
- [ ] Leaderboard integration

## Testing

### Test Challenge Flow
1. Navigate to home screen
2. Click "Beat Satan Challenge" card
3. Select 7-day challenge
4. Mark today as complete
5. Check points awarded
6. Return next day and complete again
7. Miss a day → Challenge expires

---

Built with ❤️ for the Neki Tracker app
Following Clean Architecture & Islamic principles
