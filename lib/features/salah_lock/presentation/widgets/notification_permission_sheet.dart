import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

class NotificationPermissionSheet extends StatelessWidget {
  final VoidCallback onGrant;

  const NotificationPermissionSheet({super.key, required this.onGrant});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 40.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1A13),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40.w,
            height: 4.h,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          SizedBox(height: 32.h),
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              CupertinoIcons.bell_fill,
              color: AppColors.primaryGreen,
              size: 40.sp,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            'Never Miss a Prayer',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Neki needs your permission to send precise prayer reminders and keep your streak alive.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white60,
              fontSize: 15.sp,
              height: 1.5,
            ),
          ),
          SizedBox(height: 32.h),
          _buildInfoRow(
            Icons.timer_outlined,
            'Precise Timing',
            'Ensures notifications fire exactly at Adhan time.',
          ),
          SizedBox(height: 16.h),
          _buildInfoRow(
            Icons.battery_saver_outlined,
            'Reliable Reminders',
            'Ignores battery optimizations to stay active in the background.',
          ),
          SizedBox(height: 40.h),
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: () {
                onGrant();
                context.pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                elevation: 0,
              ),
              child: Text(
                'ENABLE NOTIFICATIONS',
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          SizedBox(height: 16.h),
          TextButton(
            onPressed: () => context.pop(),
            child: Text(
              'Not now',
              style: TextStyle(
                color: Colors.white24,
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String sub) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: AppColors.goldAccent, size: 20.sp),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                sub,
                style: TextStyle(color: Colors.white38, fontSize: 12.sp),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
