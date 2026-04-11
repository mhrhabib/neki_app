import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/theme/theme_repository.dart';
import '../../features/theme/theme_cubit.dart';
import '../services/firebase_storage_service.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../location/cubit/location_cubit.dart';
import '../../features/beat_satan_chalange/domain/repositories/onboarding_repository.dart';
import '../../features/beat_satan_chalange/data/repositories/onboarding_repository_impl.dart';
import '../../features/beat_satan_chalange/presentation/cubit/onboarding_cubit.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/salah/domain/repositories/salah_repository.dart';
import '../../features/salah/data/repositories/salah_repository_impl.dart';
import '../../features/salah/presentation/cubit/salah_cubit.dart';
import '../../features/profile/domain/repositories/profile_repository.dart';
import '../../features/profile/data/repositories/profile_repository_impl.dart';
import '../../features/points/domain/repositories/points_repository.dart';
import '../../features/points/data/repositories/points_repository_impl.dart';
import '../../features/points/presentation/cubit/points_cubit.dart';
import '../../features/roza/domain/repositories/roza_repository.dart';
import '../../features/roza/data/repositories/roza_repository_impl.dart';
import '../../features/roza/presentation/cubit/roza_cubit.dart';
import '../../features/dhikir/domain/repositories/dhikir_repository.dart';
import '../../features/dhikir/data/repositories/dhikir_repository_impl.dart';
import '../../features/dhikir/presentation/cubit/dhikir_cubit.dart';
import '../../features/challenge/domain/repositories/challenge_repository.dart';
import '../../features/challenge/data/repositories/challenge_repository_impl.dart';
import '../../features/challenge/presentation/cubit/challenge_cubit.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../../features/zakat/presentation/cubit/zakat_cubit.dart';
import '../../features/salah_lock/data/services/device_management_service.dart';
import '../../features/salah_lock/data/services/salah_notification_service.dart';
import '../../features/salah_lock/domain/repositories/salah_lock_repository.dart';
import '../../features/salah_lock/data/repositories/salah_lock_repository_impl.dart';
import '../../features/salah_lock/presentation/cubit/salah_lock_cubit.dart';
import '../../features/auth/domain/repositories/premium_repository.dart';
import '../../features/auth/data/repositories/premium_repository_impl.dart';
import '../services/iap_service.dart';
import '../../features/leaderboard/domain/repositories/leaderboard_repository.dart';
import '../../features/leaderboard/data/repositories/leaderboard_repository_impl.dart';
import '../../features/leaderboard/presentation/cubit/leaderboard_cubit.dart';
import '../../core/ux/cubit/user_experience_cubit.dart';

final GetIt getIt = GetIt.instance;

class SetUpDI {
  static Future<void> init() async {
    // ========== SHARED PREFERENCES ==========
    final prefs = await SharedPreferences.getInstance();
    getIt.registerLazySingleton<SharedPreferences>(() => prefs);

    // ========== FIREBASE SERVICES ==========
    getIt.registerLazySingleton<FirebaseStorageService>(
      () => FirebaseStorageService(),
    );
    getIt.registerLazySingleton<FirestoreService>(() => FirestoreService());
    getIt.registerLazySingleton<LocationService>(() => LocationService());

    // ========== SALAH LOCK SERVICES ==========
    final notificationService = SalahNotificationService();
    await notificationService.initialize();
    getIt.registerLazySingleton<SalahNotificationService>(
      () => notificationService,
    );
    getIt.registerLazySingleton<DeviceManagementService>(
      () => DeviceManagementService(),
    );

    // ========== REPOSITORIES (Lazy Singletons) ==========
    final themeRepo = ThemeRepositoryImpl();
    await themeRepo.loadTheme(); // Load saved theme preference
    getIt.registerLazySingleton<ThemeRepository>(() => themeRepo);

    getIt.registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepositoryImpl(),
    );
    getIt.registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(firestoreService: getIt<FirestoreService>()),
    );
    getIt.registerLazySingleton<SalahRepository>(
      () => SalahRepositoryImpl(getIt<FirestoreService>()),
    );
    getIt.registerLazySingleton<SalahLockRepository>(
      () => SalahLockRepositoryImpl(getIt<SharedPreferences>()),
    );
    getIt.registerLazySingleton<PointsRepository>(
      () => PointsRepositoryImpl(
        getIt<FirestoreService>(),
        getIt<SalahLockRepository>(),
      ),
    );
    getIt.registerLazySingleton<RozaRepository>(
      () => RozaRepositoryImpl(getIt<FirestoreService>()),
    );
    getIt.registerLazySingleton<DhikirRepository>(
      () => DhikirRepositoryImpl(getIt<FirestoreService>()),
    );
    getIt.registerLazySingleton<ChallengeRepository>(
      () => ChallengeRepositoryImpl(getIt<FirestoreService>()),
    );
    getIt.registerLazySingleton<ProfileRepository>(
      () => ProfileRepositoryImpl(
        getIt<FirestoreService>(),
        getIt<FirebaseStorageService>(),
      ),
    );
    getIt.registerLazySingleton<PremiumRepository>(
      () => PremiumRepositoryImpl(getIt<SharedPreferences>()),
    );
    getIt.registerLazySingleton<IAPService>(
      () => IAPService(getIt<PremiumRepository>()),
    );
    getIt.registerLazySingleton<LeaderboardRepository>(
      () => LeaderboardRepositoryImpl(getIt<FirestoreService>()),
    );

    // ========== CUBITS (Factories) ==========
    // ThemeCubit needs to be a singleton so the same instance is shared across the app
    getIt.registerLazySingleton<ThemeCubit>(
      () => ThemeCubit(themeRepository: getIt<ThemeRepository>())..loadTheme(),
    );
    getIt.registerLazySingleton<OnboardingCubit>(
      () =>
          OnboardingCubit(onboardingRepository: getIt<OnboardingRepository>()),
    );
    getIt.registerLazySingleton<AuthCubit>(
      () => AuthCubit(authRepository: getIt<AuthRepository>()),
    );
    getIt.registerLazySingleton<SalahCubit>(
      () => SalahCubit(
        salahRepository: getIt<SalahRepository>(),
        pointsRepository: getIt<PointsRepository>(),
        challengeRepository: getIt<ChallengeRepository>(),
      ),
    );
    getIt.registerLazySingleton<PointsCubit>(
      () => PointsCubit(pointsRepository: getIt<PointsRepository>()),
    );
    getIt.registerLazySingleton<RozaCubit>(
      () => RozaCubit(
        rozaRepository: getIt<RozaRepository>(),
        pointsRepository: getIt<PointsRepository>(),
      ),
    );
    getIt.registerLazySingleton<DhikirCubit>(
      () => DhikirCubit(
        dhikirRepository: getIt<DhikirRepository>(),
        pointsRepository: getIt<PointsRepository>(),
      ),
    );
    getIt.registerLazySingleton<ChallengeCubit>(
      () => ChallengeCubit(
        getIt<ChallengeRepository>(),
        getIt<PointsRepository>(),
      ),
    );
    getIt.registerLazySingleton<ProfileCubit>(
      () => ProfileCubit(profileRepository: getIt<ProfileRepository>()),
    );
    getIt.registerLazySingleton<ZakatCubit>(
      () => ZakatCubit(getIt<PointsRepository>()),
    );
    getIt.registerLazySingleton<LocationCubit>(
      () => LocationCubit(getIt<LocationService>()),
    );
    getIt.registerLazySingleton<LeaderboardCubit>(
      () => LeaderboardCubit(
        leaderboardRepository: getIt<LeaderboardRepository>(),
        authRepository: getIt<AuthRepository>(),
      ),
    );
    getIt.registerLazySingleton<SalahLockCubit>(
      () => SalahLockCubit(
        repository: getIt<SalahLockRepository>(),
        notificationService: getIt<SalahNotificationService>(),
        deviceManager: getIt<DeviceManagementService>(),
        salahCubit: getIt<SalahCubit>(),
        locationCubit: getIt<LocationCubit>(),
        premiumRepository: getIt<PremiumRepository>(),
      ),
    );
    getIt.registerLazySingleton<UserExperienceCubit>(
      () => UserExperienceCubit(getIt<SharedPreferences>()),
    );
  }
}
