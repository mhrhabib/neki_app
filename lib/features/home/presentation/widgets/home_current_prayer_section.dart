import 'dart:async';
import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'home_prayer_helpers.dart';

/// Displays the currently active prayer name (small label), its time in large
/// digits, and the name + time of the upcoming next prayer underneath.
class HomeCurrentPrayerSection extends StatefulWidget {
  final PrayerTimes? prayerTimes;

  const HomeCurrentPrayerSection({super.key, required this.prayerTimes});

  @override
  State<HomeCurrentPrayerSection> createState() =>
      _HomeCurrentPrayerSectionState();
}

class _HomeCurrentPrayerSectionState extends State<HomeCurrentPrayerSection> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh the UI ogni minuto to keep the clock accurate
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentPrayerName = widget.prayerTimes != null
        ? getPrayerName(widget.prayerTimes!.currentPrayer()).toLowerCase()
        : '--';

    final currentTime = formatTimeOnly(DateTime.now());

    final prayerLimit = widget.prayerTimes != null
        ? formatTimeOnly(
            widget.prayerTimes!.timeForPrayer(widget.prayerTimes!.nextPrayer()),
          )
        : '--:--';

    final nextPrayerName = widget.prayerTimes != null
        ? getNextPrayerLabel(widget.prayerTimes!.nextPrayer())
        : '--';

    final nextTime = widget.prayerTimes != null
        ? formatTimeOnly(
            widget.prayerTimes!.timeForPrayer(widget.prayerTimes!.nextPrayer()),
          )
        : '--:--';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current prayer name
          Text(
            currentPrayerName,
            style: TextStyle(color: Colors.white70, fontSize: 16.sp),
          ),
          SizedBox(height: 4.h),

          // Big clock-style current time + limit
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: currentTime,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 56.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.0,
                    letterSpacing: -2,
                  ),
                ),
                TextSpan(
                  text: ' ($prayerLimit)',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 4.h),

          // Next prayer label
          Text(
            'Next prayer: $nextPrayerName',
            style: TextStyle(color: Colors.white60, fontSize: 12.sp),
          ),
          SizedBox(height: 2.h),

          // Next prayer time in accent green
          Text(
            nextTime,
            style: TextStyle(
              color: const Color(0xFF4ADE80),
              fontSize: 20.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
