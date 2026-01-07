# Neki App - AI Coding Guidelines

## Architecture Overview
This Flutter app follows **Clean Architecture** with feature-based organization. Each feature contains:
- `data/models/` - Data transfer objects and API models
- `data/repositories/` - Repository implementations with external dependencies
- `domain/entities/` - Business logic models (pure Dart, no Flutter dependencies)
- `domain/repositories/` - Abstract repository interfaces
- `presentation/cubit/` - BLoC cubits for state management
- `presentation/screens/` - UI screens

## State Management (BLoC Pattern)
**Always create cubits with this exact state structure:**
```dart
abstract class FeatureState {}

class FeatureInitial extends FeatureState {}
class FeatureLoading extends FeatureState {}
class FeatureLoaded extends FeatureState {
  final Data data;
  FeatureLoaded({required this.data});
}
class FeatureError extends FeatureState {
  final String message;
  FeatureError({required this.message});
}
```

**Cubit methods follow this pattern:**
```dart
Future<void> someAction() async {
  try {
    emit(FeatureLoading());
    final result = await repository.someMethod();
    emit(FeatureLoaded(data: result));
  } catch (e) {
    emit(FeatureError(message: e.toString()));
  }
}
```

## Dependency Injection (GetIt)
**Repository registration:** `getIt.registerLazySingleton<Repository>(() => RepositoryImpl());`
**Cubit registration:** `getIt.registerFactory<Cubit>(() => Cubit(repository: getIt<Repository>()));`
**Exception:** ThemeCubit is registered as lazy singleton since it's shared app-wide.

## Navigation (GoRouter)
- Routes defined in `lib/core/routes/route_names.dart`
- Use `context.go()` for navigation, `context.pop()` for back navigation
- Tabbed screens wrapped in `ShellRoute` with `MainScreen` builder

## Theming & Styling
- Colors defined in `lib/core/constants/app_colors.dart`
- Use `AppTheme.lightTheme()` and `AppTheme.darkTheme()`
- ScreenUtil for responsive sizing: `14.r` for radius, `24.w` for width, `12.h` for height
- Theme switching handled by `ThemeCubit`

## Project Structure Conventions
- **Core utilities:** `lib/core/utils/` (formatters, validators, helpers)
- **Shared widgets:** `lib/core/widgets/` (error screens, loading overlays)
- **Constants:** `lib/core/constants/` (colors, spacing, typography)
- **Shared components:** `lib/components/` (reusable UI components)
- **Features:** `lib/features/feature_name/` (self-contained feature modules)

## Key Dependencies & Usage
- **flutter_bloc:** State management with Cubit pattern
- **get_it:** Dependency injection container
- **go_router:** Declarative routing with shell routes for tabs
- **flutter_screenutil:** Responsive design scaling
- **shared_preferences:** Local data persistence
- **equatable:** Value equality for state objects

## Testing Setup
Widget tests require ScreenUtil initialization:
```dart
setUpAll(() async {
  await ScreenUtil.ensureScreenSize();
});
```

## Code Style Notes
- Use `debugPrint()` with emojis for logging (e.g., `debugPrint('🎨 Theme changed')`)
- Repository methods return `Future<T>` even for synchronous operations
- Error handling: Always catch exceptions and emit error states
- Points system: Salah completion awards points via `pointsRepository.addPoints()`</content>
<parameter name="filePath">/Users/becps21/bec_app/neki/neki_app/.github/copilot-instructions.md