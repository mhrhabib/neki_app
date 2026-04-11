import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../components/app_background_widget.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/location/cubit/location_cubit.dart';
import '../../../../core/location/cubit/location_state.dart';
import '../../../beat_satan_chalange/presentation/cubit/onboarding_cubit.dart';
import '../../../../core/routes/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../challenge/presentation/cubit/challenge_cubit.dart';
import '../../../challenge/presentation/widgets/challenge_progress_widget.dart';
import '../../../points/presentation/cubit/points_cubit.dart';
import '../widgets/home_all_menu_section.dart';
import '../widgets/home_current_prayer_section.dart';
import '../widgets/home_feature_cards.dart';
import '../widgets/home_user_stats_card.dart';
import '../widgets/home_prayer_times_row.dart';
import '../widgets/home_top_bar.dart';
import '../widgets/home_setup_guide_card.dart';
import '../../../salah/presentation/cubit/salah_cubit.dart';
import '../../../salah_lock/presentation/cubit/salah_lock_cubit.dart';

class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen>
    with WidgetsBindingObserver {
  bool _initialLoadDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      _triggerDataLoads(authState.user.id);
    }

    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SalahLockCubit>().checkAndRequestBasicPermissions();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAllData();
    }
  }

  void _triggerDataLoads(String userId) {
    if (_initialLoadDone) return;
    _initialLoadDone = true;
    context.read<PointsCubit>().loadUserPoints(userId);
    context.read<SalahCubit>().loadTodaysSalahs(userId);
    
    // Load challenge and auto-start if needed
    final challengeCubit = context.read<ChallengeCubit>();
    challengeCubit.loadChallenge(userId).then((_) async {
      final state = challengeCubit.state;
      if (state is ChallengeLoaded && !state.hasAnyChallenge) {
        // No active challenge, check if there's an onboarding goal to start
        final onboardingCubit = context.read<OnboardingCubit>();
        final goal = await onboardingCubit.onboardingRepository.getChallengeGoal();
        
        if (goal != null && mounted) {
          debugPrint('🚀 [Home] Auto-starting boarding goal challenge: $goal');
          await challengeCubit.startChallenge(
            userId: userId,
            durationDays: goal['days'] as int,
            rewardPoints: goal['points'] as int,
            challengeType: 'beat_satan',
          );
        }
      }
    });
  }

  /// Reload all data — called on app resume and pull-to-refresh.
  Future<void> _refreshAllData() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    final userId = authState.user.id;

    // Reload location if it errored or is stale — but NOT if permission was denied
    final locState = context.read<LocationCubit>().state;
    if (locState is LocationError || locState is LocationInitial) {
      context.read<LocationCubit>().fetchLocation();
    }
    // Re-check after returning from settings (user may have granted permission)
    if (locState is LocationPermissionDenied ||
        locState is LocationServiceDisabled) {
      context.read<LocationCubit>().fetchLocation();
    }

    // Reload Firestore-backed data in parallel
    await Future.wait([
      context.read<PointsCubit>().loadUserPoints(userId),
      context.read<SalahCubit>().loadTodaysSalahs(userId),
      context.read<ChallengeCubit>().loadChallenge(userId),
    ]);
  }

  PrayerTimes? _calculatePrayerTimes(LocationLoaded state) {
    final coordinates = Coordinates(state.latitude, state.longitude);
    final params = CalculationMethod.karachi.getParameters()
      ..madhab = Madhab.hanafi;
    final date = DateComponents.from(DateTime.now());
    return PrayerTimes(coordinates, date, params);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2818),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, authState) {
          if (authState is Authenticated) {
            _initialLoadDone = false;
            _triggerDataLoads(authState.user.id);
          }
        },
        builder: (context, authState) {
          if (authState is Authenticated) {
            return BlocBuilder<LocationCubit, LocationState>(
              builder: (context, locationState) {
                final prayerTimes = locationState is LocationLoaded
                    ? _calculatePrayerTimes(locationState)
                    : null;

                return Stack(
                  children: [
                    appBackgroundWidget(),
                    SafeArea(
                      child: RefreshIndicator(
                        onRefresh: _refreshAllData,
                        color: const Color(0xFF4ADE80),
                        backgroundColor: const Color(0xFF1A3D26),
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          slivers: [
                            SliverToBoxAdapter(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const HomeTopBar(),
                                  SizedBox(height: 8.h),
                                  HomeCurrentPrayerSection(
                                    prayerTimes: prayerTimes,
                                  ),
                                  SizedBox(height: 16.h),
                                  HomePrayerTimesRow(prayerTimes: prayerTimes),
                                  SizedBox(height: 16.h),

                                  // Location permission / error prompt
                                  if (locationState is LocationPermissionDenied)
                                    _buildLocationPermissionCard(
                                      context,
                                      locationState,
                                    )
                                  else if (locationState
                                      is LocationServiceDisabled)
                                    _buildLocationServiceCard(context)
                                  else if (locationState is LocationError ||
                                      locationState is LocationInitial)
                                    _buildFriendlyLocationPrompt(context),

                                  const HomeUserStatsCard(),
                                  const HomeSetupGuideCard(),
                                  SizedBox(height: 20.h),
                                  BlocBuilder<ChallengeCubit, ChallengeState>(
                                    builder: (context, challengeState) {
                                      if (challengeState is ChallengeLoaded &&
                                          challengeState.hasAnyChallenge) {
                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 20.w,
                                          ),
                                          child: Column(
                                            children: challengeState
                                                .challenges
                                                .entries
                                                .map(
                                                  (e) => Padding(
                                                    padding: EdgeInsets.only(
                                                      bottom: 12.h,
                                                    ),
                                                    child: GestureDetector(
                                                      onTap: () => context.push(
                                                        '${RouteNames.habitBuilding}?type=${e.key}',
                                                      ),
                                                      child:
                                                          ChallengeProgressWidget(
                                                            challenge: e.value,
                                                          ),
                                                    ),
                                                  ),
                                                )
                                                .toList(),
                                          ),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                  SizedBox(height: 20.h),
                                  const HomeAllMenuSection(),
                                  SizedBox(height: 20.h),
                                  const HomeFeatureCards(),
                                  SizedBox(height: 100.h),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }

          return const Center(
            child: CupertinoActivityIndicator(color: Colors.white),
          );
        },
      ),
    );
  }

  Widget _buildLocationPermissionCard(
    BuildContext context,
    LocationPermissionDenied state,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w).copyWith(bottom: 12.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: const Color(0xFF4ADE80).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: const Color(0xFF4ADE80).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  CupertinoIcons.location_fill,
                  color: const Color(0xFF4ADE80),
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Location Permission Needed',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'We need your location to show accurate adhan times and send prayer notifications for your area.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  if (state.permanent) {
                    context.read<LocationCubit>().openSettings();
                  } else {
                    context.read<LocationCubit>().requestAndFetch();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ADE80),
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  state.permanent ? 'Open Settings' : 'Allow Location',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationServiceCard(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w).copyWith(bottom: 12.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.orangeAccent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  CupertinoIcons.location_slash_fill,
                  color: Colors.orangeAccent,
                  size: 20.sp,
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    'Location Service Off',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            Text(
              'Turn on location services to get accurate prayer times for your area.',
              style: TextStyle(
                color: Colors.white60,
                fontSize: 13.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    context.read<LocationCubit>().openLocationSettings(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orangeAccent,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Turn On Location',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendlyLocationPrompt(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w).copyWith(bottom: 12.h),
      child: Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: AppColors.goldAccent.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: AppColors.goldAccent.withValues(alpha: 0.15),
          ),
        ),
        child: Row(
          children: [
            Icon(
              CupertinoIcons.location_circle_fill,
              color: AppColors.goldAccent,
              size: 24.sp,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update Location',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Find accurate Salah times for your area',
                    style: TextStyle(color: Colors.white60, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.read<LocationCubit>().fetchLocation(),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.goldAccent,
                padding: EdgeInsets.symmetric(horizontal: 12.w),
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
