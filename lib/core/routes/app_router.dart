import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/challenge/presentation/screens/goal_selection_screen.dart';
import '../../features/challenge/presentation/screens/habit_building_screen.dart';
import '../../features/good_deeds/presentation/screens/good_deeds_screen.dart';
import '../../features/home/presentation/screens/home_dashboard_screen.dart';
import '../../features/leaderboard/presentation/screens/leaderboard_screen.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/salah/presentation/screens/salah_screen.dart';
import '../../features/addiction/presentation/screens/addiction_screen.dart';
import '../../features/splash/presentation/screens/splash_page.dart';
import '../widgets/main_screen.dart';
import '../widgets/not_found_page.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/profile/presentation/cubit/profile_cubit.dart';
import '../di/set_up_di.dart';
import 'route_names.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    navigatorKey: navigatorKey,
    routes: [
      GoRoute(path: RouteNames.splash, builder: (context, state) => const SplashPage()),
      GoRoute(path: RouteNames.onboarding, builder: (context, state) => const OnboardingScreen()),
      GoRoute(path: RouteNames.login, builder: (context, state) => const LoginScreen()),
      GoRoute(path: RouteNames.goalSelection, builder: (context, state) => const GoalSelectionScreen()),
      GoRoute(path: RouteNames.habitBuilding, builder: (context, state) => const HabitBuildingScreen()),
      ShellRoute(
        builder: (context, state, child) => MainScreen(child: child),
        routes: [
          GoRoute(path: RouteNames.home, builder: (context, state) => const HomeDashboardScreen()),
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) =>
                BlocProvider(create: (context) => getIt<ProfileCubit>(), child: const ProfileScreen()),
          ),
          GoRoute(path: RouteNames.leaderboard, builder: (context, state) => const LeaderboardScreen()),
        ],
      ),
      GoRoute(path: RouteNames.salah, builder: (context, state) => const SalahScreen()),
      GoRoute(path: RouteNames.addiction, builder: (context, state) => const AddictionScreen()),
      GoRoute(path: RouteNames.goodDeeds, builder: (context, state) => const GoodDeedsScreen()),
    ],
    errorBuilder: (context, state) => const NotFoundPage(),
  );
}
