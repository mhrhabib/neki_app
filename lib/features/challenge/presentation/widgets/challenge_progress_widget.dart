import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../challenge/domain/entities/challenge_entity.dart';

class ChallengeProgressWidget extends StatelessWidget {
  final ChallengeEntity challenge;

  const ChallengeProgressWidget({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen, AppColors.primaryGreen.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(color: AppColors.primaryGreen.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${challenge.durationDays} Day Challenge',
                style: AppTypography.h2.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              if (challenge.isCompleted)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    '✓ Completed',
                    style: TextStyle(color: Colors.white, fontSize: 12.sp, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),

          SizedBox(height: 20.h),

          // Progress bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Day ${challenge.completedDays} of ${challenge.durationDays}',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(challenge.progress * 100).toInt()}%',
                    style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ClipRRect(
                borderRadius: BorderRadius.circular(10.r),
                child: LinearProgressIndicator(
                  value: challenge.progress,
                  minHeight: 10.h,
                  backgroundColor: Colors.white.withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ],
          ),

          SizedBox(height: 20.h),

          // Stats row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(icon: '🔥', label: 'Streak', value: '${challenge.completedDays} days'),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(icon: '⭐', label: 'Points', value: '${challenge.rewardPoints}'),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildStatCard(icon: '📅', label: 'Remaining', value: '${challenge.remainingDays} days'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String icon, required String label, required String value}) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12.r)),
      child: Column(
        children: [
          Text(icon, style: TextStyle(fontSize: 20.sp)),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(color: Colors.white, fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 10.sp),
          ),
        ],
      ),
    );
  }
}
