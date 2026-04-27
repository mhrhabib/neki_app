import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../salah/domain/entities/salah_entity.dart';

class SalahHeatmapWidget extends StatelessWidget {
  final List<SalahEntity> history;
  final bool isCompact;

  const SalahHeatmapWidget({
    super.key,
    required this.history,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // Get last 7 days (Monday to Sunday or just trailing 7)
    // Let's do trailing 7 days for a cohesive look.
    final List<DateTime> last7Days = List.generate(7, (index) {
      final day = now.subtract(Duration(days: index));
      return DateTime(day.year, day.month, day.day);
    }).reversed.toList();

    const List<String> prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

    return Container(
      padding: EdgeInsets.all(isCompact ? 12.w : 20.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isCompact) ...[
            Text(
              'WEEKLY COMPLETION',
              style: TextStyle(
                color: Colors.white38,
                fontSize: 10.sp,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            SizedBox(height: 16.h),
          ],
          Row(
            children: [
              // Y-Axis labels (Prayer Names)
              if (!isCompact)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: 20.h), // Offset for X-Axis labels
                    ...prayerNames.map((name) => Padding(
                          padding: EdgeInsets.symmetric(vertical: 4.h),
                          child: Text(
                            name[0], // Only first letter
                            style: TextStyle(
                              color: Colors.white24,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        )),
                  ],
                ),
              if (!isCompact) SizedBox(width: 8.w),
              // Heatmap Grid
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: last7Days.map((day) {
                    return Column(
                      children: [
                        // X-Axis labels (Day of week)
                        Text(
                          _getDayName(day.weekday),
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 8.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 8.h),
                        ...prayerNames.map((prayer) {
                          final isDone = _isPrayerDone(day, prayer);
                          return Container(
                            width: isCompact ? 10.w : 32.w,
                            height: isCompact ? 10.w : 32.w,
                            margin: EdgeInsets.symmetric(vertical: 2.h),
                            decoration: BoxDecoration(
                              color: isDone
                                  ? AppColors.primaryGreen.withValues(alpha: 0.8)
                                  : Colors.white10,
                              borderRadius: BorderRadius.circular(isCompact ? 4.r : 8.r),
                              border: Border.all(
                                color: isDone
                                    ? AppColors.primaryGreen
                                    : Colors.white.withValues(alpha: 0.05),
                                width: 0.5,
                              ),
                              boxShadow: isDone
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primaryGreen.withValues(alpha: 0.2),
                                        blurRadius: 4,
                                        spreadRadius: 1,
                                      )
                                    ]
                                  : null,
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isPrayerDone(DateTime day, String prayerName) {
    return history.any((salah) {
      final sDay = DateTime(salah.timestamp.year, salah.timestamp.month, salah.timestamp.day);
      return sDay.isAtSameMomentAs(day) &&
          salah.salahName == prayerName &&
          salah.isCompleted;
    });
  }

  String _getDayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}
