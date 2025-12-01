import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class ErrorScreen extends StatelessWidget {
  final String? title;
  final String? message;
  final VoidCallback? onRetry;
  final String? retryButtonText;

  const ErrorScreen({super.key, this.title, this.message, this.onRetry, this.retryButtonText});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softCream,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(32.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120.w,
                height: 120.w,
                decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Center(
                  child: Icon(Icons.error_outline_rounded, size: 60.sp, color: Colors.red),
                ),
              ),
              SizedBox(height: 32.h),
              Text(
                title ?? 'Oops! Something went wrong',
                style: AppTypography.h1.copyWith(color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                message ?? 'An unexpected error occurred. Please try again later.',
                style: AppTypography.body.copyWith(color: AppColors.textGray),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 40.h),
              if (onRetry != null)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: Icon(Icons.refresh, size: 20.sp),
                    label: Text(retryButtonText ?? 'Try Again', style: AppTypography.button),
                    style: ElevatedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 16.h)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
