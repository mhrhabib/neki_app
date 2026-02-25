import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'home_prayer_helpers.dart';

/// Horizontal scrollable strip showing all six prayer times.
/// The currently active prayer is highlighted with white text and a green dot.
class HomePrayerTimesRow extends StatelessWidget {
  final PrayerTimes? prayerTimes;

  const HomePrayerTimesRow({super.key, required this.prayerTimes});

  static const List<Map<String, dynamic>> _prayers = [
    {'name': 'Fazr', 'prayer': Prayer.fajr, 'icon': '⭐'},
    {'name': 'Sunrise', 'prayer': Prayer.sunrise, 'icon': '🌄'},
    {'name': 'Johuur', 'prayer': Prayer.dhuhr, 'icon': '🌞'},
    {'name': 'Asr', 'prayer': Prayer.asr, 'icon': '☀️'},
    {'name': 'Maghrib', 'prayer': Prayer.maghrib, 'icon': '🌅'},
    {'name': 'Isha', 'prayer': Prayer.isha, 'icon': '🌙'},
  ];

  @override
  Widget build(BuildContext context) {
    final currentPrayer = prayerTimes?.currentPrayer();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: _prayers.map((p) {
            final prayer = p['prayer'] as Prayer;
            final time = prayerTimes != null
                ? formatTimeOnly(prayerTimes!.timeForPrayer(prayer))
                : '--:--';
            final isActive = currentPrayer == prayer;

            return _PrayerTimeItem(
              name: p['name'] as String,
              icon: p['icon'] as String,
              time: time,
              isActive: isActive,
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Single item inside the prayer times row
// ---------------------------------------------------------------------------

class _PrayerTimeItem extends StatelessWidget {
  final String name;
  final String icon;
  final String time;
  final bool isActive;

  const _PrayerTimeItem({
    required this.name,
    required this.icon,
    required this.time,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white54,
            fontSize: 9.sp,
          ),
        ),
        SizedBox(height: 4.h),
        Text(icon, style: TextStyle(fontSize: 16.sp)),
        SizedBox(height: 4.h),
        Text(
          time,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.white60,
            fontSize: 11.sp,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        SizedBox(height: 4.h),
        // Active prayer indicator dot
        Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive
                ? const Color(0xFF4ADE80)
                : Colors.white.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}
