# Neki App - AI Coding Agent Instructions

## Project Overview
Neki Tracker is a Flutter mobile app for tracking Islamic good deeds (Neki means "good deed" in Urdu/Hindi). Built with Clean Architecture principles, BLoC pattern for state management, and dependency injection via GetIt.

## Architecture Pattern: Clean Architecture with Feature-First Organization

### Layer Structure (Data → Domain → Presentation)
Each feature follows a three-layer architecture:
```
features/<feature_name>/
  ├── data/
  │   ├── models/         # DTOs extending domain entities (JSON serialization)
  │   └── repositories/   # Repository implementations (currently mock data)
  ├── domain/
  │   ├── entities/       # Pure Dart domain objects (no dependencies)
  │   └── repositories/   # Abstract repository interfaces
  └── presentation/
      ├── cubit/          # BLoC state management (cubit + state in separate files)
      └── screens/        # UI components
```

**Key Rule**: Data flows **inward** only. Domain layer must NOT import from data or presentation.
- ✅ `data/models` extends `domain/entities`
- ✅ `data/repositories` implements `domain/repositories`
- ❌ Domain layer imports are forbidden from outer layers

### BLoC Pattern Convention
- Use `Cubit` (not full Bloc) for state management
- State classes use `part of` directive: `auth_state.dart` is `part of 'auth_cubit.dart'`
- Always include `part 'feature_state.dart';` in cubit files
- Emit immutable states extending `Equatable` when possible

### Dependency Injection (GetIt)
All dependencies registered in `lib/core/di/set_up_di.dart`:
- **Repositories**: `registerLazySingleton` (shared instances)
- **Cubits**: `registerFactory` (new instance per request) EXCEPT `ThemeCubit` which is a singleton
- Call `SetUpDI.init()` before `runApp()` in `main.dart`
- Access via `getIt<Type>()` in constructors

## Core Systems

### Navigation (go_router)
- Routes defined in `core/routes/app_router.dart` with named constants in `route_names.dart`
- Uses `ShellRoute` for bottom navigation persistence (home/profile/leaderboard)
- Navigate: `context.go(RouteNames.home)` or `context.push(RouteNames.salah)`
- Bottom nav screens MUST be wrapped in `MainScreen` shell

### Theme System
- Light/Dark themes centralized in `core/theme/app_theme.dart`
- Colors in `core/constants/app_colors.dart` (Islamic green/gold palette)
- Theme persistence via `SharedPreferences` in `ThemeRepository`
- Theme toggle handled by singleton `ThemeCubit`
- **Critical**: `ThemeCubit` emits `ThemeData` (not custom state) for `BlocBuilder<ThemeCubit, ThemeData>`

### Responsive Design
- All UI uses `flutter_screenutil` for responsive sizing
- Design reference: 375x812 (iPhone X)
- Always use `.w` (width), `.h` (height), `.sp` (font size), `.r` (radius) extensions
- Example: `padding: EdgeInsets.all(16.w)`, `fontSize: 14.sp`, `borderRadius: BorderRadius.circular(14.r)`

## Feature Implementation Pattern

### Creating New Features
1. Create feature folder: `lib/features/<name>/`
2. Add domain layer (entities, repository interface)
3. Add data layer (models extending entities, repository implementation)
4. Add presentation layer (cubit with state file, screens)
5. Register in DI: Repository as singleton, Cubit as factory (or singleton if needed globally)
6. Add route in `app_router.dart` and `route_names.dart`

### Points System Integration
When implementing point-earning actions (like Salah tracking):
- Inject both feature repository AND `PointsRepository` into cubit
- After successful action, call `pointsRepository.addPoints(userId: x, points: y, source: 'action_name')`
- Source string format: `'feature_action'` (e.g., `'salah_fajr'`, `'zakat_donation'`)

### Current Mock Data
All repositories currently use mock implementations with `Future.delayed()` to simulate API calls:
- `AuthRepositoryImpl`: Stores user in memory, accepts any credentials
- `SalahRepositoryImpl`: Returns hardcoded prayer times
- When replacing with real APIs, update only repository implementations in `data/` layer

## Development Workflow

### Running the App
```bash
flutter pub get                    # Install dependencies
flutter run -d <device>            # Run on specific device
flutter run                        # Run on default device
```

### Common Commands
```bash
flutter analyze                    # Static analysis
flutter test                       # Run tests
flutter clean && flutter pub get   # Clean build artifacts
```

### Adding Dependencies
1. Add to `pubspec.yaml` dependencies section
2. Run `flutter pub get`
3. If adding native dependencies, may need `cd ios && pod install`

## Code Style & Conventions

### File Naming
- Entities: `feature_entity.dart` (e.g., `user_entity.dart`)
- Models: `feature_model.dart` (e.g., `user_model.dart`)
- Repositories: `feature_repository.dart` (interface) and `feature_repository_impl.dart` (implementation)
- Screens: `descriptive_screen.dart` (e.g., `home_dashboard_screen.dart`)

### Import Organization
Follow this order:
1. Dart/Flutter SDK imports
2. Package imports (third-party)
3. Relative imports (project files)

### Debug Logging
Use `debugPrint()` with emoji prefixes for visibility:
- `debugPrint('🎨 Theme changed to: ...')` - Theme changes
- `debugPrint('✅ Action completed: ...')` - Success
- `debugPrint('❌ Error: ...')` - Errors

## Key Files Reference
- **App entry**: `lib/main.dart` - MultiBlocProvider setup
- **DI configuration**: `lib/core/di/set_up_di.dart`
- **Routing**: `lib/core/routes/app_router.dart`
- **Theme**: `lib/core/theme/app_theme.dart`, `lib/core/constants/app_colors.dart`
- **Bottom nav shell**: `lib/core/widgets/main_screen.dart`

## Active Features
- ✅ Onboarding (first-time user flow)
- ✅ Authentication (Firebase Auth with Email/Password, Google, Facebook, Apple Sign-In)
- ✅ Platform-specific authentication (Apple Sign-In shows only on iOS using `Platform.isIOS`)
- ✅ OAuth2 with PKCE for Apple Sign-In (nonce generation and SHA-256 hashing)
- ✅ Salah tracking (5 daily prayers with points)
- ✅ Points system (centralized point management)
- ✅ Home dashboard
- ✅ Profile & Leaderboard
- 🚧 Good Deeds, Roza, Zakat (structures exist, UI/logic incomplete)

## ⚠️ CRITICAL: Firebase Dynamic Links Deprecation
**IMMEDIATE ACTION REQUIRED**: Firebase Dynamic Links will shut down soon, breaking authentication flows that depend on it:
- Email link authentication for mobile apps
- Cordova OAuth support for web apps

**Impact**: Authentication features using Firebase Dynamic Links will stop working. This affects:
- Email link sign-in flows
- OAuth redirects through Firebase Dynamic Links

**Migration Status**: ✅ **COMPLETED**
- Updated all Firebase packages to latest versions
- Verified current auth implementation uses direct OAuth flows (no Dynamic Links dependency)
- All authentication methods (Email/Password, Google, Facebook, Apple) use direct Firebase Auth SDK calls
- No email link authentication currently implemented

**Action Required**: 
1. ✅ Updated Firebase packages to latest versions
2. Monitor for any authentication issues after Dynamic Links shutdown
3. Test all authentication providers thoroughly
4. Update documentation and user-facing messaging if needed

## Authentication Implementation
The app uses Firebase Authentication with multiple providers:
- **Email/Password**: Standard Firebase email auth
- **Google Sign-In**: OAuth2 with Google, uses `google_sign_in` package
- **Facebook Login**: OAuth2 with Facebook, uses `flutter_facebook_auth` package  
- **Apple Sign-In (iOS only)**: OAuth2 with PKCE, uses `sign_in_with_apple` package
  - Implemented with nonce generation for security
  - Shows conditionally using `dart:io Platform.isIOS` check
  - Handles first-time user name capture (Apple only provides name on first sign-in)
  
See `FIREBASE_SETUP.md` for general Firebase setup and `APPLE_SIGNIN_SETUP.md` for Apple-specific configuration.
