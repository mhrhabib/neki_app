import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../challenge/domain/entities/challenge_entity.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/challenge_cubit.dart';

class ChallengeProgressWidget extends StatelessWidget {
  final ChallengeEntity challenge;

  const ChallengeProgressWidget({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    final bool isExpired = challenge.hasExpired();
    
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: isExpired 
            ? Colors.redAccent.withValues(alpha: 0.1) 
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: isExpired 
              ? Colors.redAccent.withValues(alpha: 0.3) 
              : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _challengeLabel(challenge.challengeType),
                    style: TextStyle(color: Colors.white60, fontSize: 13.sp),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    _headlineFor(challenge),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
           if (challenge.isCompleted || challenge.isAtMilestone)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 8.h,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppColors.successGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: AppColors.successGreen,
                        size: 14.sp,
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'Completed',
                        style: TextStyle(
                          color: AppColors.successGreen,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 28.h),
          
          if (isExpired) ...[
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.redAccent.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 24.sp),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          'You missed your streak!',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    'Don\'t feel discouraged. The true victory is continually returning to the good path. Start again right now.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13.sp,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        final authState = context.read<AuthCubit>().state;
                        if (authState is Authenticated) {
                          context.read<ChallengeCubit>().startChallenge(
                            userId: authState.user.id,
                            durationDays: challenge.durationDays,
                            rewardPoints: challenge.rewardPoints,
                            challengeType: challenge.challengeType,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Restart Challenge ↻',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      challenge.effectiveDuration > 0
                          ? 'Day ${challenge.progressDays} of ${challenge.effectiveDuration}'
                          : 'Days Clean: ${challenge.daysClean}',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      challenge.effectiveDuration > 0
                          ? '${(challenge.progress * 100).toInt()}%'
                          : '∞', // Past every milestone — celebrate forever
                      style: TextStyle(
                        color: AppColors.goldAccent,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Stack(
                  children: [
                    Container(
                      height: 10.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                    ),
                    FractionallySizedBox(
                      widthFactor: challenge.progress,
                      child: Container(
                        height: 10.h,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryGreen, Color(0xFF50C878)],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryGreen.withValues(
                                alpha: 0.3,
                              ),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 28.h),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.local_fire_department,
                    label: 'Streak',
                    value: '${challenge.isAddictionType ? challenge.daysClean : challenge.completedDays}',
                    color: Colors.orangeAccent,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.stars_rounded,
                    label: 'Neki Pts',
                    value: '${challenge.currentMilestone?.points ?? challenge.rewardPoints}',
                    color: AppColors.goldAccent,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildStatItem(
                    icon: Icons.calendar_today_rounded,
                    label: 'To Go',
                    value: '${challenge.remainingDays}',
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Big-text headline shown above the progress bar.
  /// - Fixed challenges (Beat Satan, legacy `_7`): "{N} Day Challenge"
  /// - Unbounded addictions with a current milestone: e.g. "1 Week Clean"
  /// - Unbounded addictions past every milestone: "Continuous Sobriety"
  String _headlineFor(ChallengeEntity c) {
    if (c.durationDays > 0) return '${c.durationDays} Day Challenge';
    final m = c.currentMilestone;
    if (m != null) return m.title;
    return 'Continuous Sobriety';
  }

  String _challengeLabel(String? type) {
    if (type == null) return 'Current Marathon';
    if (type == 'beat_satan') return 'Beat Satan Challenge';
    if (type.startsWith('addiction_')) {
      final parts = type.split('_');
      if (parts.length >= 2) {
        switch (parts[1]) {
          case 'porn':
            return 'Porn Recovery';
          case 'smoking':
            return 'Smoking Recovery';
          case 'alcohol':
            return 'Alcohol Recovery';
          case 'gambling':
            return 'Gambling Recovery';
        }
      }
      return 'Addiction Recovery';
    }
    return 'Current Marathon';
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white38,
              fontSize: 9.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}
