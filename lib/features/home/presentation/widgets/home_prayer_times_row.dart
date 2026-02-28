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

    return SizedBox(
      height: 90.h,
      child: ListView.separated(
        padding: EdgeInsets.symmetric(horizontal: 20.w),
        scrollDirection: Axis.horizontal,
        itemCount: _prayers.length,
        separatorBuilder: (context, index) => SizedBox(width: 10.w),
        itemBuilder: (context, index) {
          final p = _prayers[index];
          final prayer = p['prayer'] as Prayer;
          final time = prayerTimes != null
              ? formatTimeOnly(prayerTimes!.timeForPrayer(prayer))
              : '--:--';
          final isActive = currentPrayer == prayer;

          return _PrayerCard(
            name: p['name'] as String,
            icon: p['icon'] as String,
            time: time,
            isActive: isActive,
          );
        },
      ),
    );
  }
}

class _PrayerCard extends StatelessWidget {
  final String name;
  final String icon;
  final String time;
  final bool isActive;

  const _PrayerCard({
    required this.name,
    required this.icon,
    required this.time,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 75.w,
      padding: EdgeInsets.all(8.w),
      decoration: BoxDecoration(
        color: isActive
            ? Colors.white.withValues(alpha: 0.12)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isActive
              ? const Color(0xFF4ADE80).withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
          width: isActive ? 1.5 : 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(icon, style: TextStyle(fontSize: 14.sp)),
              if (isActive)
                Icon(
                  Icons.check_circle_rounded,
                  size: 12.sp,
                  color: const Color(0xFF4ADE80),
                ),
            ],
          ),
          const Spacer(),
          Text(
            name,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.white70,
              fontSize: 10.sp,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            time,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
