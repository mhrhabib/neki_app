import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import '../../../../core/routes/route_names.dart';
import '../../../points/presentation/cubit/points_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../challenge/presentation/cubit/challenge_cubit.dart';
import '../../../../core/location/cubit/location_cubit.dart';
import '../../../../core/location/cubit/location_state.dart';
import '../../../../components/app_background_widget.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  static const List<Map<String, dynamic>> _menuItems = [
    {'title': 'Habit Tracker', 'icon': '📋', 'route': RouteNames.habitBuilding},
    {'title': 'Dallu Dua', 'icon': '🤲', 'route': RouteNames.salah},
    {'title': 'Quran', 'icon': '📖', 'route': RouteNames.quran},
    {'title': 'Tasbeeh', 'icon': '📿', 'route': RouteNames.dhikir},
  ];

  PrayerTimes? _calculatePrayerTimes(LocationLoaded state) {
    final coordinates = Coordinates(state.latitude, state.longitude);
    final params = CalculationMethod.karachi.getParameters();
    params.madhab = Madhab.hanafi;
    final date = DateComponents.from(DateTime.now());
    return PrayerTimes(coordinates, date, params);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2818),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is Authenticated) {
            context.read<PointsCubit>().loadUserPoints(authState.user.id);
            context.read<ChallengeCubit>().loadChallenge(authState.user.id);

            return BlocBuilder<LocationCubit, LocationState>(
              builder: (context, locationState) {
                PrayerTimes? prayerTimes;
                if (locationState is LocationLoaded) {
                  prayerTimes = _calculatePrayerTimes(locationState);
                }

                return Stack(
                  children: [
                    appBackgroundWidget(),
                    SafeArea(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: 100.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTopBar(context),
                            SizedBox(height: 8.h),
                            _buildCurrentPrayerSection(context, prayerTimes),
                            SizedBox(height: 16.h),
                            _buildPrayerTimesRow(context, prayerTimes),
                            SizedBox(height: 16.h),
                            _buildJohuurCard(context, prayerTimes),
                            SizedBox(height: 20.h),
                            _buildAllMenuSection(context),
                            SizedBox(height: 20.h),
                            _buildFeatureCards(context, authState.user.id),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Location pill
          BlocBuilder<LocationCubit, LocationState>(
            builder: (context, state) {
              String locationText = 'Fetching...';
              if (state is LocationLoaded) {
                locationText = state.address;
              } else if (state is LocationError) {
                locationText = 'Location Error';
              }

              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      CupertinoIcons.location_fill,
                      color: Colors.white70,
                      size: 12.sp,
                    ),
                    SizedBox(width: 4.w),
                    Text(
                      locationText,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          // Profile icon
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
            ),
            child: Icon(
              CupertinoIcons.person_fill,
              color: Colors.white70,
              size: 18.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPrayerSection(
    BuildContext context,
    PrayerTimes? prayerTimes,
  ) {
    String currentPrayerName = '--';
    String currentTime = '--:--';
    String nextPrayerName = '--';
    String nextTime = '--:--';

    if (prayerTimes != null) {
      final current = prayerTimes.currentPrayer();
      final next = prayerTimes.nextPrayer();

      currentPrayerName = _getPrayerName(current).toLowerCase();
      currentTime = _formatTimeOnly(prayerTimes.timeForPrayer(current));

      nextPrayerName = _getNextPrayerLabel(next);
      nextTime = _formatTimeOnly(prayerTimes.timeForPrayer(next));
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            currentPrayerName,
            style: TextStyle(color: Colors.white70, fontSize: 16.sp),
          ),
          SizedBox(height: 4.h),
          Text(
            currentTime,
            style: TextStyle(
              color: Colors.white,
              fontSize: 56.sp,
              fontWeight: FontWeight.w700,
              height: 1.0,
              letterSpacing: -2,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Next prayer: $nextPrayerName',
            style: TextStyle(color: Colors.white60, fontSize: 12.sp),
          ),
          SizedBox(height: 2.h),
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

  String _formatTimeOnly(DateTime? time) {
    if (time == null) return '--:--';
    return DateFormat('HH:mm').format(time);
  }

  String _getPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'Fazr';
      case Prayer.sunrise:
        return 'Sunrise';
      case Prayer.dhuhr:
        return 'Johuur';
      case Prayer.asr:
        return 'Asr';
      case Prayer.maghrib:
        return 'Maghrib';
      case Prayer.isha:
        return 'Isha';
      case Prayer.none:
        return 'Isha';
    }
  }

  String _getNextPrayerLabel(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'Fazr (dawn prayer)';
      case Prayer.sunrise:
        return 'Sunrise';
      case Prayer.dhuhr:
        return 'Johuur (noon prayer)';
      case Prayer.asr:
        return 'Asr (afternoon prayer)';
      case Prayer.maghrib:
        return 'Maghrib (sunset prayer)';
      case Prayer.isha:
        return 'Isha (night prayer)';
      default:
        return 'Isha (night prayer)';
    }
  }

  Widget _buildPrayerTimesRow(BuildContext context, PrayerTimes? prayerTimes) {
    final List<Map<String, dynamic>> prayers = [
      {'name': 'Fazr', 'prayer': Prayer.fajr, 'icon': '⭐'},
      {'name': 'Sunrise', 'prayer': Prayer.sunrise, 'icon': '🌄'},
      {'name': 'Johuur', 'prayer': Prayer.dhuhr, 'icon': '🌞'},
      {'name': 'Asr', 'prayer': Prayer.asr, 'icon': '☀️'},
      {'name': 'Maghrib', 'prayer': Prayer.maghrib, 'icon': '🌅'},
      {'name': 'Isha', 'prayer': Prayer.isha, 'icon': '🌙'},
    ];

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
          children: prayers.map((p) {
            final time = prayerTimes != null
                ? _formatTimeOnly(
                    prayerTimes.timeForPrayer(p['prayer'] as Prayer),
                  )
                : '--:--';
            final isActive = currentPrayer == p['prayer'];
            return _buildPrayerTimeItem(
              context,
              name: p['name'] as String,
              time: time,
              icon: p['icon'] as String,
              isActive: isActive,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildPrayerTimeItem(
    BuildContext context, {
    required String name,
    required String time,
    required String icon,
    bool isActive = false,
  }) {
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

  Widget _buildJohuurCard(BuildContext context, PrayerTimes? prayerTimes) {
    String johuurTime = '--:--';
    String asrTime = '--:--';

    if (prayerTimes != null) {
      johuurTime = DateFormat.jm().format(prayerTimes.dhuhr);
      asrTime = DateFormat.jm().format(prayerTimes.asr);
    }

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
              child: Column(
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
              ),
            ),
            // Quran illustration placeholder
            Container(
              width: 80.w,
              height: 80.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text('📖', style: TextStyle(fontSize: 40.sp)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllMenuSection(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'All Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'See More',
                  style: TextStyle(
                    color: const Color(0xFF4ADE80),
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        SizedBox(
          height: 90.h,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _menuItems.length,
            itemBuilder: (context, index) {
              final item = _menuItems[index];
              return GestureDetector(
                onTap: () => context.push(item['route'] as String),
                child: Container(
                  width: 72.w,
                  margin: EdgeInsets.only(right: 12.w),
                  child: Column(
                    children: [
                      Container(
                        width: 56.w,
                        height: 56.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A3D26),
                          borderRadius: BorderRadius.circular(14.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            item['icon'] as String,
                            style: TextStyle(fontSize: 26.sp),
                          ),
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        item['title'] as String,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10.sp,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureCards(BuildContext context, String userId) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: BlocBuilder<ChallengeCubit, ChallengeState>(
        builder: (context, state) {
          return Row(
            children: [
              Expanded(child: _buildAddictionCard(context, state)),
              SizedBox(width: 12.w),
              Expanded(child: _buildChallengeCard(context, state)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddictionCard(BuildContext context, ChallengeState state) {
    final hasActive =
        state is ChallengeLoaded &&
        state.hasActiveChallenge &&
        state.challenge != null &&
        state.challenge!.challengeType != null &&
        state.challenge!.challengeType!.startsWith('addiction_');

    return GestureDetector(
      onTap: () => context.push(
        hasActive ? RouteNames.habitBuilding : RouteNames.addiction,
      ),
      child: Container(
        height: 140.h,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E4D35), Color(0xFF0D2818)],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Stack(
          children: [
            // 3D mosque icon placeholder
            Positioned(
              top: 0,
              right: 0,
              child: Text('🕌', style: TextStyle(fontSize: 40.sp)),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Addiction Recover',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    hasActive ? 'View your plan' : 'Start a recover plan',
                    style: TextStyle(color: Colors.white60, fontSize: 10.sp),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: const Color(0xFF4ADE80),
                      size: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(BuildContext context, ChallengeState state) {
    final hasActive =
        state is ChallengeLoaded &&
        state.hasActiveChallenge &&
        (state.challenge?.challengeType == null ||
            !state.challenge!.challengeType!.startsWith('addiction_'));

    return GestureDetector(
      onTap: () => context.push(
        hasActive ? RouteNames.habitBuilding : RouteNames.goalSelection,
      ),
      child: Container(
        height: 140.h,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3D50), Color(0xFF0D2030)],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Stack(
          children: [
            // Kaaba / dome icon placeholder
            Positioned(
              top: 0,
              right: 0,
              child: Text('🕋', style: TextStyle(fontSize: 40.sp)),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Best Satan Challeng',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    hasActive
                        ? 'Continue your journey'
                        : 'Start buiding you daily neki',
                    style: TextStyle(color: Colors.white60, fontSize: 10.sp),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.all(6.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: const Color(0xFF4ADE80),
                      size: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
