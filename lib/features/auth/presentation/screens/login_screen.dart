import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/auth_cubit.dart';
import '../../../../components/app_background_widget.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // void _handleContinue(BuildContext context) {
  //   context.go(RouteNames.home);
  // }

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
    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Authenticated) {
            // No manual context.go needed, GoRouter will redirect reactively
          } else if (state is AuthError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          final authLoading = state is AuthLoading ? state : null;
          final isAnyLoading = authLoading != null;

          return Stack(
            children: [
              appBackgroundWidget(),
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 32.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Icon Container
                      Image.asset('assets/kabba_1.png', height: 200.h),
                      // Welcome Back Title
                      Text(
                        'Welcome Back',
                        style: GoogleFonts.sanchez(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldAccent,
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: 12.h),

                      // Subtitle
                      Text(
                        'Continue your spiritual journey',
                        style: GoogleFonts.sanchez(
                          fontSize: 14.sp,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 60.h),

                      // Continue with Google Button
                      _buildAuthButton(
                        context: context,
                        icon: '🔐',
                        label: 'Continue with Google',
                        onPressed: isAnyLoading
                            ? () {}
                            : () => _handleGoogleSignIn(context),
                        isLoading: authLoading?.loadingProvider == 'google',
                      ),
                      SizedBox(height: 16.h),

                      // Continue with Facebook Button
                      _buildAuthButton(
                        context: context,
                        icon: '📱',
                        label: 'Continue with Facebook',
                        onPressed: isAnyLoading
                            ? () {}
                            : () => _handleFacebookSignIn(context),
                        isLoading: authLoading?.loadingProvider == 'facebook',
                      ),

                      // Show Apple Sign-In only on iOS or macOS
                      if (Platform.isIOS || Platform.isMacOS) ...[
                        SizedBox(height: 16.h),
                        _buildAuthButton(
                          context: context,
                          icon: '',
                          label: 'Continue with Apple',
                          onPressed: isAnyLoading
                              ? () {}
                              : () => _handleAppleSignIn(context),
                          isLoading: authLoading?.loadingProvider == 'apple',
                        ),
                      ],

                      SizedBox(height: 40.h),

                      // Continue as Guest
                      // TextButton(
                      //   onPressed: isAnyLoading
                      //       ? null
                      //       : () => _handleContinue(context),
                      //   child: Text(
                      //     'Continue as Guest',
                      //     style: GoogleFonts.sanchez(
                      //       color: Colors.white60,
                      //       fontSize: 14.sp,
                      //       fontWeight: FontWeight.w500,
                      //       decoration: TextDecoration.underline,
                      //       decorationColor: Colors.white30,
                      //     ),
                      //   ),
                      // ),
                    ],
                  ),
                ),
              ),
            ],
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
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: isLoading
            ? SizedBox(
                height: 24.h,
                width: 24.h,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(icon, style: TextStyle(fontSize: 24.sp)),
                  SizedBox(width: 16.w),
                  Text(
                    label,
                    style: GoogleFonts.sanchez(
                      color: Colors.white,
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
