import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/home/presentation/screens/home_dashboard_screen.dart';
import '../../features/salah/presentation/screens/salah_screen.dart';
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';
import '../constants/app_spacing.dart';
import 'route_names.dart';

class AppRouter {
  static GoRouter router(BuildContext context) {
    final onboardingCubit = context.read<OnboardingCubit>();
    final authCubit = context.read<AuthCubit>();

    return GoRouter(
      initialLocation: RouteNames.splash,
      redirect: (context, state) {
        // Check onboarding status
        final onboardingState = onboardingCubit.state;
        final authState = authCubit.state;

        // If on splash, allow navigation
        if (state.matchedLocation == RouteNames.splash) {
          return null;
        }

        // If not onboarded and not going to onboarding, redirect
        if (onboardingState is OnboardingNotCompleted && state.matchedLocation != RouteNames.onboarding) {
          return RouteNames.onboarding;
        }

        // If onboarded but not authenticated and not going to login, redirect
        if (authState is! Authenticated &&
            state.matchedLocation != RouteNames.login &&
            state.matchedLocation != RouteNames.onboarding) {
          return RouteNames.login;
        }

        return null;
      },
      routes: [
        GoRoute(path: RouteNames.splash, builder: (context, state) => const SplashPage()),
        GoRoute(path: RouteNames.onboarding, builder: (context, state) => const OnboardingScreen()),
        GoRoute(path: RouteNames.login, builder: (context, state) => const LoginScreen()),
        GoRoute(path: RouteNames.home, builder: (context, state) => const HomeDashboardScreen()),
        GoRoute(path: RouteNames.salah, builder: (context, state) => const SalahScreen()),
      ],
      errorBuilder: (context, state) => const NotFoundPage(),
    );
  }
}

// Splash Page Widget
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (mounted) {
      context.go(RouteNames.onboarding);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryGreen,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌙', style: TextStyle(fontSize: 80.sp)),
            SizedBox(height: 24.h),
            Text(
              'NEKI TRACKER',
              style: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }
}

// Not Found Page Widget
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softCream,
      appBar: AppBar(title: const Text('Page Not Found')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.outerPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80.sp, color: Colors.red),
              SizedBox(height: 16.h),
              Text('404', style: AppTypography.h1.copyWith(fontSize: 48.sp)),
              SizedBox(height: 8.h),
              Text('Page not found', style: AppTypography.body),
              SizedBox(height: 32.h),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.home),
                child: Text('Go Home', style: AppTypography.button),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
