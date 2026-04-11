import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../salah/domain/entities/salah_entity.dart';

class SalahIntensityChart extends StatelessWidget {
  final List<SalahEntity> history;
  final int daysInRange;

  const SalahIntensityChart({
    super.key,
    required this.history,
    this.daysInRange = 30,
  });

  @override
  Widget build(BuildContext context) {
    // Process data: count completions per prayer type
    final Map<String, int> completedCounts = {
      'Fajr': 0,
      'Dhuhr': 0,
      'Asr': 0,
      'Maghrib': 0,
      'Isha': 0,
    };

    for (final salah in history) {
      if (completedCounts.containsKey(salah.salahName) && salah.isCompleted) {
        completedCounts[salah.salahName] =
            completedCounts[salah.salahName]! + 1;
      }
    }

    final List<String> prayerNames = [
      'Fajr',
      'Dhuhr',
      'Asr',
      'Maghrib',
      'Isha',
    ];

    return Container(
      height: 200.h,
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: prayerNames.map((name) {
          final completed = completedCounts[name]!;
          // Completion rate is completions divided by total days (potential occurrences)
          final completionRate = (completed / daysInRange).clamp(0.0, 1.0);
          final missCount = daysInRange - completed;

          return _BarItem(
            label: name,
            value: completionRate,
            missCount: missCount,
          );
        }).toList(),
      ),
    );
  }
}

class _BarItem extends StatelessWidget {
  final String label;
  final double value; // 0.0 to 1.0
  final int missCount;

  const _BarItem({
    required this.label,
    required this.value,
    required this.missCount,
  });

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (missCount > 0)
            Text(
              '-$missCount',
              style: TextStyle(
                color: Colors.redAccent.withValues(alpha: 0.6),
                fontSize: 9.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          SizedBox(height: 4.h),
          Stack(
            alignment: Alignment.bottomCenter,
            children: [
              // Background bar
              Container(
                width: 14.w,
                height: 120.h,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              // Progress bar
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                curve: Curves.easeOutCubic,
                width: 14.w,
                height: (120 * value).h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.primaryGreen,
                      AppColors.primaryGreen.withValues(alpha: 0.4),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryGreen.withValues(alpha: 0.2),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            label.substring(0, 3).toUpperCase(),
            style: TextStyle(
              color: Colors.white24,
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
