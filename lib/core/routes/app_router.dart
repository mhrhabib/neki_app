import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/challenge/presentation/screens/habit_building_screen.dart';
import '../../features/onboarding/presentation/screens/goal_selection_screen.dart'
    as onboarding;
import '../../features/onboarding/presentation/screens/habit_building_screen.dart'
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
import '../../features/splash/presentation/screens/splash_page.dart';
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

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    navigatorKey: navigatorKey,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: RouteNames.goalSelection,
        builder: (context, state) => const onboarding.GoalSelectionScreen(),
      ),
      GoRoute(
        path: RouteNames.habitBuildingOnboarding,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const onboarding.HabitBuildingScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      ),
      GoRoute(
        path: RouteNames.habitBuilding,
        builder: (context, state) => const HabitBuildingScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) => const HomeDashboardScreen(),
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => BlocProvider(
              create: (context) => getIt<ProfileCubit>(),
              child: const ProfileScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.leaderboard,
            builder: (context, state) => const LeaderboardScreen(),
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.salah,
        builder: (context, state) => const SalahScreen(),
      ),
      GoRoute(
        path: RouteNames.roza,
        builder: (context, state) => BlocProvider(
          create: (context) => getIt<RozaCubit>(),
          child: const RozaScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.dhikir,
        builder: (context, state) => BlocProvider(
          create: (context) => getIt<DhikirCubit>(),
          child: const DhikirScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.zakat,
        builder: (context, state) => BlocProvider(
          create: (context) => getIt<ZakatCubit>(),
          child: const ZakatScreen(),
        ),
      ),
      GoRoute(
        path: RouteNames.addiction,
        builder: (context, state) => const AddictionScreen(),
      ),
      GoRoute(
        path: RouteNames.goodDeeds,
        builder: (context, state) => const GoodDeedsScreen(),
      ),
      GoRoute(
        path: RouteNames.qibla,
        builder: (context, state) => const QiblaCompassScreen(),
      ),
      GoRoute(
        path: RouteNames.namesOfAllah,
        builder: (context, state) => const NamesScreen(),
      ),
      GoRoute(
        path: RouteNames.calendar,
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: RouteNames.quran,
        builder: (context, state) => const QuranHomeScreen(),
        routes: [
          GoRoute(
            path: ':surahNumber',
            builder: (context, state) {
              final surahNumber = int.parse(
                state.pathParameters['surahNumber']!,
              );
              return SurahDetailScreen(surahNumber: surahNumber);
            },
          ),
        ],
      ),
      GoRoute(
        path: RouteNames.salahLockSettings,
        builder: (context, state) => const SalahLockSettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
}
