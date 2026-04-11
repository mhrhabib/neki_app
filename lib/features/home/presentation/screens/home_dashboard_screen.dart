import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:neki_app/core/ux/cubit/user_experience_cubit.dart';
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
import '../../../salah_lock/presentation/widgets/notification_permission_sheet.dart';
import '../../../salah/presentation/cubit/salah_cubit.dart';
import '../../../salah_lock/presentation/cubit/salah_lock_cubit.dart';
import '../widgets/celebration_overlay.dart';

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

  void _checkNotificationsPermission() async {
    final salahLockCubit = context.read<SalahLockCubit>();
    final isEnabled = await salahLockCubit.notificationService
        .areNotificationsEnabled();

    if (!isEnabled && mounted) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => NotificationPermissionSheet(
          onGrant: () => salahLockCubit.checkAndRequestBasicPermissions(),
        ),
      );
    }
  }

  void _triggerDataLoads(String userId) {
    if (_initialLoadDone) return;
    _initialLoadDone = true;
    _checkNotificationsPermission();
    context.read<PointsCubit>().loadUserPoints(userId);
    context.read<SalahCubit>().loadTodaysSalahs(userId);
    context.read<SalahCubit>().loadSalahHistory(
      userId: userId,
      startDate: DateTime.now().subtract(const Duration(days: 7)),
      endDate: DateTime.now(),
    );

    // Load challenge and auto-start if needed
    final challengeCubit = context.read<ChallengeCubit>();
    challengeCubit.loadChallenge(userId).then((_) async {
      final state = challengeCubit.state;
      if (state is ChallengeLoaded && !state.hasAnyChallenge) {
        // No active challenge, check if there's an onboarding goal to start
        final onboardingCubit = context.read<OnboardingCubit>();
        final goal = await onboardingCubit.onboardingRepository
            .getChallengeGoal();

        if (goal != null && mounted) {
          debugPrint('🚀 [Home] Auto-starting boarding goal challenge: $goal');
          await challengeCubit.startChallenge(
            userId: userId,
            durationDays: goal['days'] as int,
            rewardPoints: goal['points'] as int,
            challengeType: goal['type'] as String,
          );

          if (mounted) {
            _showCelebration(
              title: 'Challenge Started!',
              subtitle:
                  'You\'ve taken the first step on your ${goal['type']} journey. Keep it up!',
              points: '50', // Bonus for starting
            );
          }
        }
      }
    });
  }

  void _showCelebration({
    required String title,
    required String subtitle,
    required String points,
  }) {
    final uxCubit = context.read<UserExperienceCubit>();
    if (uxCubit.state.hasCelebratedFirstWin) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return CelebrationOverlay(
          title: title,
          subtitle: subtitle,
          points: points,
          onClaim: () {
            uxCubit.markFirstWinCelebrated();
            Navigator.of(context).pop();
          },
        );
      },
    );
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
      context.read<SalahCubit>().loadSalahHistory(
        userId: userId,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      ),
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
                      child: MultiBlocListener(
                        listeners: [
                          BlocListener<SalahCubit, SalahState>(
                            listenWhen: (previous, current) {
                              if (previous is SalahLoading &&
                                  current is SalahLoaded) {
                                // If we just loaded and a prayer was marked complete...
                                return true;
                              }
                              return false;
                            },
                            listener: (context, state) {
                              if (state is SalahLoaded) {
                                final hasCompletedAny = state.salahs.any(
                                  (s) => s.isCompleted,
                                );
                                final uxCubit = context
                                    .read<UserExperienceCubit>();
                                if (hasCompletedAny &&
                                    !uxCubit.state.hasCelebratedFirstWin) {
                                  _showCelebration(
                                    title: 'Your First Prayer!',
                                    subtitle:
                                        'Mabrook! You\'ve just recorded your first prayer on Neki. May Allah accept it.',
                                    points:
                                        '100', // Major bonus for first prayer
                                  );
                                }
                              }
                            },
                          ),
                        ],
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
                                    HomePrayerTimesRow(
                                      prayerTimes: prayerTimes,
                                    ),
                                    SizedBox(height: 16.h),

                                    // Location permission / error prompt
                                    if (locationState
                                        is LocationPermissionDenied)
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
                                        if (challengeState
                                                is ChallengeLoading ||
                                            challengeState
                                                is ChallengeInitial) {
                                          return Padding(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 20.w,
                                            ),
                                            child: Container(
                                              height: 100.h,
                                              decoration: BoxDecoration(
                                                color: Colors.white.withValues(
                                                  alpha: 0.03,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(24.r),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.05),
                                                ),
                                              ),
                                              child: const Center(
                                                child:
                                                    CupertinoActivityIndicator(
                                                      color: Colors.white24,
                                                    ),
                                              ),
                                            ),
                                          );
                                        }

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
                                                              challenge:
                                                                  e.value,
                                                            ),
                                                      ),
                                                    ),
                                                  )
                                                  .toList(),
                                            ),
                                          );
                                        }
                                        return const _NoActiveChallengeCard();
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

class _NoActiveChallengeCard extends StatelessWidget {
  const _NoActiveChallengeCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1E4D35).withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.03),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text('🚀', style: TextStyle(fontSize: 24.sp)),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ignite Your Journey',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Start a challenge to build consistency and earn Neki points.',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 13.sp,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(RouteNames.goalSelection),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: Colors.black,
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'START CHALLENGE',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
