import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:neki_app/core/routes/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/auth_cubit.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  void _handleContinue(BuildContext context) {
    // Simulate login with mock user
    // context.read<AuthCubit>().login(email: 'user@example.com', password: 'password');
    context.go(RouteNames.home);
  }

  void _handleGoogleSignIn(BuildContext context) {
    context.read<AuthCubit>().signInWithGoogle();
  }

  void _handleFacebookSignIn(BuildContext context) {
    context.read<AuthCubit>().signInWithFacebook();
  }

  void _handleAppleSignIn(BuildContext context) {
    context.read<AuthCubit>().signInWithApple();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : Colors.white,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            context.go('/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final authLoading = state is AuthLoading ? state : null;
          final isAnyLoading = authLoading != null;

          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 32.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Icon Container
                  Container(
                    width: 100.w,
                    height: 100.w,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(25.r), color: AppColors.goldAccent),
                    child: Center(
                      child: Text(
                        '🕌',
                        style: TextStyle(fontSize: 48.sp, color: AppColors.primaryGreen),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Welcome Back Title
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.primaryGreen,
                    ),
                  ),
                  SizedBox(height: 8.h),

                  // Subtitle
                  Text(
                    'Continue your spiritual journey',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 60.h),

                  // Continue with Google Button
                  _buildAuthButton(
                    context: context,
                    icon: '🔐',
                    label: 'Continue with Google',
                    onPressed: isAnyLoading ? () {} : () => _handleGoogleSignIn(context),
                    isLoading: authLoading?.loadingProvider == 'google',
                  ),
                  SizedBox(height: 12.h),

                  // Continue with Facebook Button
                  _buildAuthButton(
                    context: context,
                    icon: '📱',
                    label: 'Continue with Facebook',
                    onPressed: isAnyLoading ? () {} : () => _handleFacebookSignIn(context),
                    isLoading: authLoading?.loadingProvider == 'facebook',
                  ),

                  // Show Apple Sign-In only on iOS or macOS
                  if (Platform.isIOS || Platform.isMacOS) ...[
                    SizedBox(height: 12.h),
                    _buildAuthButton(
                      context: context,
                      icon: '',
                      label: 'Continue with Apple',
                      onPressed: isAnyLoading ? () {} : () => _handleAppleSignIn(context),
                      isLoading: authLoading?.loadingProvider == 'apple',
                    ),
                  ],

                  SizedBox(height: 32.h),

                  // Continue as Guest
                  TextButton(
                    onPressed: isAnyLoading ? null : () => _handleContinue(context),
                    child: Text(
                      'Continue as Guest',
                      style: TextStyle(
                        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAuthButton({
    required BuildContext context,
    required String icon,
    required String label,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          side: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB), width: 1.5),
        ),
        child: isLoading
            ? SizedBox(
                height: 24.h,
                width: 24.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(isDark ? Colors.white : AppColors.primaryGreen),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(icon, style: TextStyle(fontSize: 24.sp)),
                  SizedBox(width: 12.w),
                  Text(
                    label,
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
