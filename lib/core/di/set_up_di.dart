import 'package:get_it/get_it.dart';
import '../../features/theme/theme_repository.dart';
import '../../features/theme/theme_cubit.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/data/repositories/onboarding_repository_impl.dart';
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/salah/domain/repositories/salah_repository.dart';
import '../../features/salah/data/repositories/salah_repository_impl.dart';
import '../../features/salah/presentation/cubit/salah_cubit.dart';
import '../../features/points/domain/repositories/points_repository.dart';
import '../../features/points/data/repositories/points_repository_impl.dart';
import '../../features/points/presentation/cubit/points_cubit.dart';

final GetIt getIt = GetIt.instance;

class SetUpDI {
  static Future<void> init() async {
    // ========== REPOSITORIES (Lazy Singletons) ==========
    final themeRepo = ThemeRepositoryImpl();
    await themeRepo.loadTheme(); // Load saved theme preference
    getIt.registerLazySingleton<ThemeRepository>(() => themeRepo);

    getIt.registerLazySingleton<OnboardingRepository>(() => OnboardingRepositoryImpl());
    getIt.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl());
    getIt.registerLazySingleton<SalahRepository>(() => SalahRepositoryImpl());
    getIt.registerLazySingleton<PointsRepository>(() => PointsRepositoryImpl());

    // ========== CUBITS (Factories) ==========
    // ThemeCubit needs to be a singleton so the same instance is shared across the app
    getIt.registerLazySingleton<ThemeCubit>(() => ThemeCubit(themeRepository: getIt<ThemeRepository>())..loadTheme());
    getIt.registerFactory<OnboardingCubit>(() => OnboardingCubit(onboardingRepository: getIt<OnboardingRepository>()));
    getIt.registerFactory<AuthCubit>(() => AuthCubit(authRepository: getIt<AuthRepository>()));
    getIt.registerFactory<SalahCubit>(
      () => SalahCubit(salahRepository: getIt<SalahRepository>(), pointsRepository: getIt<PointsRepository>()),
    );
    getIt.registerFactory<PointsCubit>(() => PointsCubit(pointsRepository: getIt<PointsRepository>()));
  }
}
