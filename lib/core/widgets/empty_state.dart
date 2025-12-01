import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class EmptyState extends StatelessWidget {
  final String icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: 80.sp)),
            SizedBox(height: 24.h),
            Text(
              title,
              style: AppTypography.h2.copyWith(color: AppColors.textDark),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 12.h),
            Text(
              message,
              style: AppTypography.body.copyWith(color: AppColors.textGray),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 32.h),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!, style: AppTypography.button),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
