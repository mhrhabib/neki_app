import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

/// Highlighted card showing today's Johuur (Dhuhr) time and
/// the upcoming Asr time as the next prayer.
class HomeJohuurCard extends StatelessWidget {
  final PrayerTimes? prayerTimes;

  const HomeJohuurCard({super.key, required this.prayerTimes});

  @override
  Widget build(BuildContext context) {
    final johuurTime = prayerTimes != null
        ? DateFormat.jm().format(prayerTimes!.dhuhr)
        : '--:--';
    final asrTime = prayerTimes != null
        ? DateFormat.jm().format(prayerTimes!.asr)
        : '--:--';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1A3D26),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _PrayerInfo(johuurTime: johuurTime, asrTime: asrTime),
            ),
            _QuranIllustration(),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _PrayerInfo extends StatelessWidget {
  final String johuurTime;
  final String asrTime;

  const _PrayerInfo({required this.johuurTime, required this.asrTime});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Johuur',
          style: TextStyle(color: Colors.white54, fontSize: 12.sp),
        ),
        SizedBox(height: 4.h),
        Text(
          johuurTime,
          style: TextStyle(
            color: Colors.white,
            fontSize: 28.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: -1,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          'Next Pray: Asr',
          style: TextStyle(color: Colors.white54, fontSize: 11.sp),
        ),
        Text(
          asrTime,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _QuranIllustration extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80.w,
      height: 80.w,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Center(
        child: Text('📖', style: TextStyle(fontSize: 40.sp)),
      ),
    );
  }
}
