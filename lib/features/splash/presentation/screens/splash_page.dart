import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

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
    if (!mounted) return;

    // Check onboarding status
    final onboardingCubit = context.read<OnboardingCubit>();
    final authCubit = context.read<AuthCubit>();

    // Wait for both checks to complete
    await Future.wait([onboardingCubit.checkOnboarding(), authCubit.checkAuthStatus()]);

    if (!mounted) return;

    final onboardingState = onboardingCubit.state;
    final authState = authCubit.state;

    // Navigate based on onboarding and auth status
    if (onboardingState is OnboardingCompleted) {
      // User has completed onboarding
      if (authState is Authenticated) {
        // User is authenticated, go to home
        context.go(RouteNames.home);
      } else {
        // User is not authenticated, go to login
        context.go(RouteNames.login);
      }
    } else {
      // User hasn't completed onboarding, show goal selection
      context.go(RouteNames.goalSelection);
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
