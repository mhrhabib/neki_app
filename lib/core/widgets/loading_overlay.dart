import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;
  final String? message;

  const LoadingOverlay({super.key, required this.isLoading, required this.child, this.message});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.5),
            child: Center(
              child: Container(
                padding: EdgeInsets.all(24.w),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.r)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryGreen)),
                    if (message != null) ...[
                      SizedBox(height: 16.h),
                      Text(
                        message!,
                        style: TextStyle(fontSize: 14.sp, color: AppColors.textDark),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
