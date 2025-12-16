import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routes/route_names.dart';
import '../cubit/challenge_cubit.dart';

class GoalSelectionScreen extends StatelessWidget {
  const GoalSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : AppColors.softCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.outerPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20.h),
              Text(
                '🎯 Choose Your Goal',
                style: AppTypography.h1.copyWith(color: isDark ? Colors.white : AppColors.textDark, fontSize: 28.sp),
              ),
              SizedBox(height: 12.h),
              Text(
                'Select how many days you want to commit to building this habit',
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textGray,
                  fontSize: 16.sp,
                ),
              ),
              SizedBox(height: 40.h),

              // 7 Days Challenge
              _ChallengeCard(
                days: 7,
                points: 70,
                icon: '🌱',
                title: 'Beginner',
                subtitle: 'Perfect for starting your journey',
                color: const Color(0xFF4CAF50),
                onTap: () => _startChallenge(context, 7, 70),
              ),

              SizedBox(height: 20.h),

              // 14 Days Challenge
              _ChallengeCard(
                days: 14,
                points: 150,
                icon: '🔥',
                title: 'Intermediate',
                subtitle: 'Build strong habits',
                color: const Color(0xFFFF9800),
                onTap: () => _startChallenge(context, 14, 150),
              ),

              SizedBox(height: 20.h),

              // 21 Days Challenge
              _ChallengeCard(
                days: 21,
                points: 250,
                icon: '💎',
                title: 'Advanced',
                subtitle: 'Master your discipline',
                color: const Color(0xFF9C27B0),
                onTap: () => _startChallenge(context, 21, 250),
              ),

              const Spacer(),

              // Info box
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1F2937).withOpacity(0.5) : AppColors.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: isDark ? const Color(0xFF374151) : AppColors.primaryGreen.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: isDark ? Colors.white70 : AppColors.primaryGreen, size: 24.sp),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'Complete daily tasks to earn points. Miss a day and the challenge resets!',
                        style: AppTypography.caption.copyWith(color: isDark ? Colors.white70 : AppColors.textGray),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startChallenge(BuildContext context, int days, int points) {
    context.read<ChallengeCubit>().startChallenge(
      durationDays: days,
      rewardPoints: points,
      challengeType: 'beat_satan',
    );

    // Navigate to habit building screen
    context.push(RouteNames.habitBuilding);
  }
}

class _ChallengeCard extends StatelessWidget {
  final int days;
  final int points;
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ChallengeCard({
    required this.days,
    required this.points,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: isDark ? const Color(0xFF374151) : AppColors.dividerGray),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            // Icon container
            Container(
              width: 60.w,
              height: 60.w,
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12.r)),
              child: Center(
                child: Text(icon, style: TextStyle(fontSize: 32.sp)),
              ),
            ),

            SizedBox(width: 16.w),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$days Days',
                        style: AppTypography.h2.copyWith(
                          color: isDark ? Colors.white : AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          title,
                          style: TextStyle(color: color, fontSize: 10.sp, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(color: isDark ? Colors.white60 : AppColors.textGray),
                  ),
                ],
              ),
            ),

            // Points badge
            Column(
              children: [
                Icon(Icons.star, color: AppColors.goldAccent, size: 24.sp),
                SizedBox(height: 4.h),
                Text(
                  '$points',
                  style: AppTypography.h2.copyWith(
                    color: AppColors.goldAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
                Text(
                  'points',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textGray,
                    fontSize: 10.sp,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
