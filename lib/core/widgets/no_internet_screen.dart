import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class NoInternetScreen extends StatelessWidget {
  final VoidCallback? onRetry;

  const NoInternetScreen({super.key, this.onRetry});

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
                decoration: BoxDecoration(color: AppColors.primaryGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Center(
                  child: Icon(Icons.wifi_off_rounded, size: 60.sp, color: AppColors.primaryGreen),
                ),
              ),
              SizedBox(height: 32.h),
              Text(
                'No Internet Connection',
                style: AppTypography.h1.copyWith(color: AppColors.textDark),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12.h),
              Text(
                'Please check your internet connection and try again',
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
                    label: Text('Try Again', style: AppTypography.button),
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
