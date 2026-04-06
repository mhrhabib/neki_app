import 'dart:io';

import 'package:adhan/adhan.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../components/app_background_widget.dart';
import '../../../../core/location/cubit/location_cubit.dart';
import '../../../../core/location/cubit/location_state.dart';
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
    context.read<ChallengeCubit>().loadChallenge(userId);
    context.read<SalahCubit>().loadTodaysSalahs(userId);
  }

  /// Reload all data — called on app resume and pull-to-refresh.
  Future<void> _refreshAllData() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! Authenticated) return;
    final userId = authState.user.id;

    // Reload location if it errored or is stale
    final locState = context.read<LocationCubit>().state;
    if (locState is LocationError || locState is LocationInitial) {
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
                                  HomePrayerTimesRow(
                                    prayerTimes: prayerTimes,
                                  ),
                                  SizedBox(height: 16.h),

                                  // Location error banner
                                  if (locationState is LocationError)
                                    _buildLocationErrorBanner(context),

                                  const HomeUserStatsCard(),
                                  const HomeSetupGuideCard(),
                                  SizedBox(height: 20.h),
                                  BlocBuilder<ChallengeCubit, ChallengeState>(
                                    builder: (context, challengeState) {
                                      if (challengeState is ChallengeLoaded &&
                                          challengeState.challenge != null &&
                                          challengeState.challenge!.isActive) {
                                        return Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 20.w,
                                          ),
                                          child: GestureDetector(
                                            onTap: () => context.push(
                                              RouteNames.habitBuilding,
                                            ),
                                            child: ChallengeProgressWidget(
                                              challenge:
                                                  challengeState.challenge!,
                                            ),
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

  Widget _buildLocationErrorBanner(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w).copyWith(bottom: 12.h),
      child: GestureDetector(
        onTap: () => context.read<LocationCubit>().fetchLocation(),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: Colors.redAccent.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.location_slash_fill,
                color: Colors.redAccent,
                size: 18.sp,
              ),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'Location unavailable — prayer times may be inaccurate',
                  style: TextStyle(
                    color: Colors.white60,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'Retry',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
