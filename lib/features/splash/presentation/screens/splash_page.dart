import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
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
    await Future.wait([
      onboardingCubit.checkOnboarding(),
      authCubit.checkAuthStatus(),
    ]);

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
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // 1. Background Gradient/Texture effect
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [Color(0xFF202020), Color(0xFF000000)],
                ),
              ),
            ),
          ),

          // 2. Faded Mosque Asset at the top (Sketch style)
          Positioned(
            top: -50.h,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/Mosque-01 1.png',
                fit: BoxFit.fitWidth,
                width: 1.sw,
              ),
            ),
          ),

          // 3. Side Decorations (Mandalas)
          Positioned(
            left: 0.w,
            bottom: 200.h,
            child: Opacity(
              opacity: 0.4,
              child: Image.asset('assets/Shape-07 1.png', width: 100.w),
            ),
          ),
          Positioned(
            right: -1.w,
            bottom: 50.h,
            child: Opacity(
              opacity: 0.3,
              child: Image.asset('assets/Shape-04 1.png', width: 100.w),
            ),
          ),

          Positioned(
            top: 50.h,
            left: 10.w,
            child: Align(
              alignment: AlignmentGeometry.topCenter,
              child: Image.asset('assets/Mosque-01 1.png', height: 230.h),
            ),
          ),

          // 5. Central Logo and Text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Container
                SizedBox(height: 10.h),
                Image.asset('assets/kabba_1.png', height: 80.h),

                // Stylized Brand Name
                Text(
                  'NEKI',
                  style: TextStyle(
                    fontSize: 42.sp,
                    fontWeight: FontWeight.w900,
                    color: AppColors.goldAccent,
                    letterSpacing: 4,
                    fontFamily: GoogleFonts.sanchez()
                        .fontFamily, // Use a more premium look
                  ),
                ),
                Text(
                  'TRACKER',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.goldAccent.withValues(alpha: 0.7),
                    letterSpacing: 6,
                    fontWeight: FontWeight.w300,
                    fontFamily: GoogleFonts.sanchez().fontFamily,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
