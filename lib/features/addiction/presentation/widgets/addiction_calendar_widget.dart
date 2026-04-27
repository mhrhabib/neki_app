import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../challenge/domain/entities/challenge_entity.dart';

class AddictionCalendarWidget extends StatelessWidget {
  final ChallengeEntity challenge;

  const AddictionCalendarWidget({super.key, required this.challenge});

  @override
  Widget build(BuildContext context) {
    // For addiction (unbounded), show a message instead of a fixed-duration calendar
    if (challenge.durationDays == 0) {
      return Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'RECOVERY PROGRESS',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  '${challenge.daysClean} Days Clean',
                  style: TextStyle(
                    color: AppColors.goldAccent,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 20.h),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.trending_up, color: AppColors.goldAccent, size: 24.sp),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'Your sobriety journey continues indefinitely. Every day is a victory — there\'s no "finish line" to addiction recovery.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13.sp,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Show the actual duration of the challenge (for non-addiction challenges)
    final totalDaysToShow = challenge.durationDays;
    
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'RECOVERY PROGRESS',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              Text(
                '${challenge.completedDays}/$totalDaysToShow Days',
                style: TextStyle(
                  color: AppColors.goldAccent,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 8.h,
              crossAxisSpacing: 8.w,
            ),
            itemCount: totalDaysToShow,
            itemBuilder: (context, index) {
              final dayNumber = index + 1;
              final isCompleted = index < challenge.completedDays;
              final isToday = index == challenge.completedDays;
              
              // Determine status: 
              // 1. Completed (Green)
              // 2. Missed (Red - if before today and not completed)
              // 3. Today (Yellow/Gold border)
              // 4. Future (Empty)
              
              Color bgColor = Colors.white.withValues(alpha: 0.05);
              Color borderColor = Colors.white.withValues(alpha: 0.1);
              Widget? content;

              if (isCompleted) {
                bgColor = AppColors.successGreen.withValues(alpha: 0.2);
                borderColor = AppColors.successGreen.withValues(alpha: 0.4);
                content = Icon(Icons.check, color: AppColors.successGreen, size: 14.sp);
              } else if (index < challenge.completedDays) {
                 // Logic for missed days would go here if we tracked individual days.
                 // For now, based on completedDays, all days before completedDays are Green.
                 // If we find a gap (missedYesterday), the heatmap logic needs individual day data.
                 // Reusing ChallengeEntity which only has completedDays (count).
              } else if (isToday) {
                borderColor = AppColors.goldAccent;
              }

              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: borderColor, width: 1.5),
                ),
                child: Center(
                  child: content ?? Text(
                    dayNumber.toString(),
                    style: TextStyle(
                      color: isToday ? AppColors.goldAccent : Colors.white24,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
