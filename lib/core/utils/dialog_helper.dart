import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

class DialogHelper {
  static Future<bool?> showConfirmation(
    BuildContext context, {
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDangerous = false,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(title, style: AppTypography.h2),
        content: Text(message, style: AppTypography.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(cancelText ?? 'Cancel', style: AppTypography.body.copyWith(color: AppColors.textGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: isDangerous ? Colors.red : AppColors.primaryGreen),
            child: Text(confirmText ?? 'Confirm', style: AppTypography.button),
          ),
        ],
      ),
    );
  }

  static Future<void> showMessage(
    BuildContext context, {
    required String title,
    required String message,
    String? buttonText,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        title: Text(title, style: AppTypography.h2),
        content: Text(message, style: AppTypography.body),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(buttonText ?? 'OK', style: AppTypography.button),
          ),
        ],
      ),
    );
  }

  static Future<void> showSuccess(BuildContext context, {required String title, required String message}) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(color: AppColors.successGreen.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.check_circle, color: AppColors.successGreen, size: 48.sp),
            ),
            SizedBox(height: 16.h),
            Text(title, style: AppTypography.h2, textAlign: TextAlign.center),
            SizedBox(height: 8.h),
            Text(message, style: AppTypography.body, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Done', style: AppTypography.button),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> showError(BuildContext context, {required String title, required String message}) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(Icons.error, color: Colors.red, size: 48.sp),
            ),
            SizedBox(height: 16.h),
            Text(title, style: AppTypography.h2, textAlign: TextAlign.center),
            SizedBox(height: 8.h),
            Text(message, style: AppTypography.body, textAlign: TextAlign.center),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Close', style: AppTypography.button),
            ),
          ),
        ],
      ),
    );
  }

  static void showBottomSheet(BuildContext context, {required Widget child, bool isDismissible = true}) {
    showModalBottomSheet(
      context: context,
      isDismissible: isDismissible,
      enableDrag: isDismissible,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20.r), topRight: Radius.circular(20.r)),
        ),
        child: child,
      ),
    );
  }
}
