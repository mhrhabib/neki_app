import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'home_prayer_helpers.dart';
import '../../../salah/presentation/cubit/salah_cubit.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import 'package:go_router/go_router.dart';

/// Horizontal scrollable strip showing all six prayer times.
/// Includes a compact Salah tracker on top.
class HomePrayerTimesRow extends StatelessWidget {
  final PrayerTimes? prayerTimes;

  const HomePrayerTimesRow({super.key, required this.prayerTimes});

  static const List<Map<String, dynamic>> _prayers = [
    {'name': 'Fazr', 'prayer': Prayer.fajr, 'icon': '⭐'},
    {'name': 'Johuur', 'prayer': Prayer.dhuhr, 'icon': '🌞'},
    {'name': 'Asr', 'prayer': Prayer.asr, 'icon': '☀️'},
    {'name': 'Maghrib', 'prayer': Prayer.maghrib, 'icon': '🌅'},
    {'name': 'Isha', 'prayer': Prayer.isha, 'icon': '🌙'},
  ];

  @override
  Widget build(BuildContext context) {
    final currentPrayer = prayerTimes?.currentPrayer();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSalahTracker(context),
        SizedBox(height: 16.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: SizedBox(
            height: 95.h,
            child: Row(
              children: _prayers.asMap().entries.map((entry) {
                final index = entry.key;
                final p = entry.value;
                final prayer = p['prayer'] as Prayer;
                final time = prayerTimes != null ? formatTimeOnly(prayerTimes!.timeForPrayer(prayer)) : '--:--';
                final isActive = currentPrayer == prayer;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: index == 0 ? 0 : 4.w, right: index == _prayers.length - 1 ? 0 : 4.w),
                    child: _PrayerCard(
                      name: p['name'] as String,
                      icon: p['icon'] as String,
                      time: time,
                      isActive: isActive,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSalahTracker(BuildContext context) {
    return BlocBuilder<SalahCubit, SalahState>(
      builder: (context, state) {
        if (state is SalahLoaded) {
          final prayers = [
            {'name': 'Fajr', 'initial': 'F'},
            {'name': 'Dhuhr', 'initial': 'D'},
            {'name': 'Asr', 'initial': 'A'},
            {'name': 'Maghrib', 'initial': 'M'},
            {'name': 'Isha', 'initial': 'I'},
          ];

          return GestureDetector(
            onTap: () => context.push(RouteNames.salah),
            child: SizedBox(
              height: 48.h, // Explicit height for the tracker row
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                margin: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Row(
                  children: [
                    Text(
                      'Salah Tracker',
                      style: TextStyle(color: AppColors.goldAccent, fontSize: 13.sp, fontWeight: FontWeight.w800),
                    ),
                    // const Spacer(),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        reverse: true, // Show most recent/right-aligned prayers first if overflowing
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: prayers.map((p) {
                            final isDone = state.salahs.any((s) => s.salahName == p['name'] && s.isCompleted);
                            return Container(
                              width: 24.w,
                              height: 24.w,
                              margin: EdgeInsets.only(left: 6.w),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDone
                                    ? AppColors.successGreen.withValues(alpha: 0.2)
                                    : Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: isDone
                                      ? AppColors.successGreen.withValues(alpha: 0.5)
                                      : Colors.white.withValues(alpha: 0.1),
                                  width: 1.w,
                                ),
                                boxShadow: isDone
                                    ? [BoxShadow(color: AppColors.successGreen.withValues(alpha: 0.2), blurRadius: 4)]
                                    : [],
                              ),
                              child: Center(
                                child: Text(
                                  p['initial']!,
                                  style: TextStyle(
                                    color: isDone ? Colors.white : Colors.white24,
                                    fontSize: 10.sp,
                                    fontWeight: isDone ? FontWeight.w900 : FontWeight.w600,
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.arrow_forward_ios, size: 10.sp, color: Colors.white24),
                  ],
                ),
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }
}

class _PrayerCard extends StatelessWidget {
  final String name;
  final String icon;
  final String time;
  final bool isActive;

  const _PrayerCard({required this.name, required this.icon, required this.time, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 102.h,
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primaryGreen.withValues(alpha: 0.15) : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isActive ? AppColors.primaryGreen.withValues(alpha: 0.4) : Colors.white.withValues(alpha: 0.08),
          width: 1.5.w,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ]
            : [],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(icon, style: TextStyle(fontSize: 16.sp)),
              if (isActive)
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: const BoxDecoration(color: AppColors.successGreen, shape: BoxShape.circle),
                  child: Icon(Icons.check, size: 8.sp, color: Colors.white),
                ),
            ],
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              name,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white60,
                fontSize: 11.sp,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          SizedBox(height: 2.h),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              time,
              style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
