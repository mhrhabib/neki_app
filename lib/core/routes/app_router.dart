import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/challenge/presentation/screens/habit_building_screen_for_addiction.dart';
import '../../features/onboarding/presentation/screens/premium_onboarding_screen.dart'
    as onboarding;
import '../../features/good_deeds/presentation/screens/good_deeds_screen.dart';
import '../../features/home/presentation/screens/home_dashboard_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/salah/presentation/screens/salah_screen.dart';
import '../../features/addiction/presentation/screens/addiction_screen.dart';
import '../../features/roza/presentation/screens/roza_screen.dart';
import '../../features/roza/presentation/cubit/roza_cubit.dart';
import '../../features/zakat/presentation/screens/zakat_screen.dart';
import '../../features/zakat/presentation/cubit/zakat_cubit.dart';
import '../../features/names_of_allah/presentation/screens/names_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/dhikir/presentation/screens/dhikir_screen.dart';
import '../../features/dhikir/presentation/cubit/dhikir_cubit.dart';
import '../../features/splash/presentation/screens/splash_screen.dart';
import '../../features/qibla/presentation/screens/qibla_compass_screen.dart';
import '../../features/quran/presentation/screens/quran_home_screen.dart';
import '../../features/quran/presentation/screens/surah_detail_screen.dart';
import '../../features/salah_lock/presentation/screens/salah_lock_settings_screen.dart';
import '../widgets/main_screen.dart';
import '../widgets/not_found_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../di/set_up_di.dart';
import 'route_names.dart';
import 'go_router_refresh_stream.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/screens/paywall_screen.dart';
import '../../features/home/presentation/screens/journey_screen.dart';
import '../../features/beat_satan_chalange/presentation/cubit/onboarding_cubit.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    navigatorKey: navigatorKey,
    refreshListenable: GoRouterRefreshStream([
      getIt<AuthCubit>().stream,
      getIt<OnboardingCubit>().stream,
    ]),
    redirect: (context, state) {
      final authState = getIt<AuthCubit>().state;
      final onboardingState = getIt<OnboardingCubit>().state;

      debugPrint('🚀 [Router] Path: ${state.matchedLocation}');
      debugPrint('🚀 [Router] Auth: ${authState.runtimeType}');
      debugPrint('🚀 [Router] Onboarding: ${onboardingState.runtimeType}');

      final isSplash = state.matchedLocation == RouteNames.splash;
      final isLogin = state.matchedLocation == RouteNames.login;
      final isOnboarding =
          state.matchedLocation == RouteNames.premiumOnboarding;

      // 1. SPLASH GATE: Only block on Splash if we are still initializing
      // We wait for BOTH Auth and Onboarding to be beyond Initial/Loading.
      if (isSplash) {
        if (authState is AuthInitial ||
            authState is AuthLoading ||
            onboardingState is OnboardingInitial) {
          debugPrint('🚀 [Router] Still initializing, staying on Splash');
          return null;
        }
      }

      // If there's an error, we should probably allow navigation to Login/Home
      // instead of being stuck.
      if (authState is AuthError || onboardingState is OnboardingError) {
        debugPrint(
          '🚀 [Router] Found Error state, proceeding to check other flags',
        );
      }

      // 2. FORCE ONBOARDING: If not completed, we MUST go there (even if we are Unauthenticated)
      if (onboardingState is OnboardingNotCompleted) {
        if (!isOnboarding) {
          debugPrint('🚀 [Router] Redirecting to Onboarding (Premium)');
          return RouteNames.premiumOnboarding;
        }
        return null; // Stay in onboarding flow
      }

      // 3. AUTH CHECK: If onboarding is done, check if we need to login
      if (authState is Unauthenticated) {
        if (!isLogin) {
          debugPrint('🚀 [Router] Redirecting to Login');
          return RouteNames.login;
        }
        return null; // Stay on login
      }

      // 4. HOME REDIRECT: If both completed, go home if user is trying to reach splash/login/onboarding
      if (authState is Authenticated && onboardingState is OnboardingCompleted) {
        if (isLogin || isSplash || isOnboarding) {
          debugPrint('🚀 [Router] All clear, redirecting to Home');
          return RouteNames.home;
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.splash,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(child: const SplashScreen(), state: state),
      ),
      GoRoute(
        path: RouteNames.login,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(child: const LoginScreen(), state: state),
      ),
      GoRoute(
        path: RouteNames.premiumOnboarding,
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: const onboarding.PremiumOnboardingScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: RouteNames.habitBuilding,
        pageBuilder: (context, state) {
          final typeKey = state.uri.queryParameters['type'];
          return _buildPageWithTransition(
            child: HabitBuildingScreenForAddiction(typeKey: typeKey),
            state: state,
          );
        },
      ),
      GoRoute(
        path: RouteNames.premium,
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: const PaywallScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: RouteNames.journey,
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: const JourneyScreen(),
          state: state,
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const HomeDashboardScreen(),
              state: state,
            ),
          ),
          GoRoute(
            path: RouteNames.profile,
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: BlocProvider.value(
                value: getIt<ProfileCubit>(),
                child: const ProfileScreen(),
              ),
              state: state,
            ),
          ),
          GoRoute(
            path: RouteNames.leaderboard,
            pageBuilder: (context, state) => _buildPageWithTransition(
              child: const LeaderboardScreen(),
              state: state,
            ),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.salah,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(child: const SalahScreen(), state: state),
      ),
      GoRoute(
        path: RouteNames.roza,
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: BlocProvider.value(
            value: getIt<RozaCubit>(),
            child: const RozaScreen(),
          ),
          state: state,
        ),
      ),
      GoRoute(
        path: RouteNames.dhikir,
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: BlocProvider.value(
            value: getIt<DhikirCubit>(),
            child: const DhikirScreen(),
          ),
          state: state,
        ),
      ),
      GoRoute(
        path: RouteNames.zakat,
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: BlocProvider.value(
            value: getIt<ZakatCubit>(),
            child: const ZakatScreen(),
          ),
          state: state,
        ),
      ),
      GoRoute(
        path: RouteNames.addiction,
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: const AddictionScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: RouteNames.goodDeeds,
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: const GoodDeedsScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: RouteNames.qibla,
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: const QiblaCompassScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: RouteNames.namesOfAllah,
        pageBuilder: (context, state) =>
            _buildPageWithTransition(child: const NamesScreen(), state: state),
      ),
      GoRoute(
        path: RouteNames.calendar,
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: const CalendarScreen(),
          state: state,
        ),
      ),
      GoRoute(
        path: RouteNames.quran,
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: const QuranHomeScreen(),
          state: state,
        ),
        routes: [
          GoRoute(
            path: ':surahNumber',
            pageBuilder: (context, state) {
              final surahNumber = int.parse(
                state.pathParameters['surahNumber']!,
              );
              return _buildPageWithTransition(
                child: SurahDetailScreen(surahNumber: surahNumber),
                state: state,
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.salahLockSettings,
        pageBuilder: (context, state) => _buildPageWithTransition(
          child: const SalahLockSettingsScreen(),
          state: state,
        ),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );

  /// Helper to build a page with a consistent transition
  static CustomTransitionPage _buildPageWithTransition({
    required Widget child,
    required GoRouterState state,
  }) {
    return CustomTransitionPage(
      key: state.pageKey,
      child: child,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        // Fade + subtle scale/slide effect
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: animation.drive(
              Tween<Offset>(
                begin: const Offset(0.05, 0),
                end: Offset.zero,
              ).chain(CurveTween(curve: Curves.easeOutCubic)),
            ),
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }
}
