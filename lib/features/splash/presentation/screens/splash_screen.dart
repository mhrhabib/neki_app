import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:neki_app/components/app_background_widget.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../beat_satan_chalange/presentation/cubit/onboarding_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  Future<void> _navigateToNext() async {
    debugPrint('🚀 [SplashScreen] Starting initialization...');
    // 1. Trigger initial status checks
    context.read<OnboardingCubit>().checkOnboarding();
    context.read<AuthCubit>().checkAuthStatus();

    // 2. Minimum splash delay for branding
    debugPrint('🚀 [SplashScreen] Waiting for branding delay...');
    await Future.delayed(const Duration(seconds: 2));
    debugPrint('🚀 [SplashScreen] Branding delay finished.');
    
    // Note: No manual context.go() needed here. 
    // GoRouter will automatically redirect based on the states 
    // updated above because of the refreshListenable in AppRouter.
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Stack(
        children: [
          // 1. Background Gradient/Texture effect
          appBackgroundWidget(),

          // 2. Faded Mosque Asset at the top (Sketch style)
          // Positioned(
          //   top: -50.h,
          //   left: 0,
          //   right: 0,
          //   child: Opacity(
          //     opacity: 0.15,
          //     child: Image.asset(
          //       'assets/Mosque-01 1.png',
          //       fit: BoxFit.fitWidth,
          //       width: 1.sw,
          //     ),
          //   ),
          // ),

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

          // Positioned(
          //   top: 50.h,
          //   left: 10.w,
          //   child: Align(
          //     alignment: AlignmentGeometry.topCenter,
          //     child: Image.asset('assets/Mosque-01 1.png', height: 230.h),
          //   ),
          // ),

          // 5. Central Logo and Text
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo Container
                SizedBox(height: 10.h),
                Image.asset('assets/kabba_1.png', height: 100.h),

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
