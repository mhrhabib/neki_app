import 'dart:io';

import 'package:adhan/adhan.dart';
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

/// Home dashboard screen.
///
/// Acts as an orchestrator: it wires up Blocs/Cubits and hands off
/// the individual UI sections to self-contained widget files found in
/// `lib/features/home/presentation/widgets/`.
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  @override
  void initState() {
    super.initState();
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      _triggerDataLoads(authState.user.id);
    }
    // Request alarm + battery permissions after the first frame so the
    // Activity is fully ready to launch system dialogs.
    if (Platform.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<SalahLockCubit>().checkAndRequestBasicPermissions();
      });
    }
  }

  void _triggerDataLoads(String userId) {
    context.read<PointsCubit>().loadUserPoints(userId);
    context.read<ChallengeCubit>().loadChallenge(userId);
    context.read<SalahCubit>().loadTodaysSalahs(userId);
  }

  // -------------------------------------------------------------------------
  // Prayer time calculation
  // -------------------------------------------------------------------------

  PrayerTimes? _calculatePrayerTimes(LocationLoaded state) {
    final coordinates = Coordinates(state.latitude, state.longitude);
    final params = CalculationMethod.karachi.getParameters()
      ..madhab = Madhab.hanafi;
    final date = DateComponents.from(DateTime.now());
    return PrayerTimes(coordinates, date, params);
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2818),
      body: BlocConsumer<AuthCubit, AuthState>(
        listener: (context, authState) {
          if (authState is Authenticated) {
            // Trigger data loads when transitioning to Authenticated
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
                    // Decorative background layer
                    appBackgroundWidget(),

                    // Scrollable content
                    SafeArea(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.only(bottom: 100.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Top bar (location pill + profile) ───────────
                            const HomeTopBar(),
                            SizedBox(height: 8.h),

                            // ── Current prayer name + time ───────────────────
                            HomeCurrentPrayerSection(prayerTimes: prayerTimes),
                            SizedBox(height: 16.h),

                            // ── All-six-prayers horizontal strip ─────────────
                            HomePrayerTimesRow(prayerTimes: prayerTimes),
                            SizedBox(height: 16.h),

                            // ── User stats card (Points + Streak) ───────────
                            const HomeUserStatsCard(),
                            const HomeSetupGuideCard(),
                            SizedBox(height: 20.h),

                            // ── Active Challenge progress card ───────────────
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
                                        challenge: challengeState.challenge!,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                            ),
                            SizedBox(height: 20.h),

                            // ── Quick-access menu icons ──────────────────────
                            const HomeAllMenuSection(),
                            SizedBox(height: 20.h),

                            // ── Addiction + Challenge feature cards ──────────
                            const HomeFeatureCards(),
                            SizedBox(height: 20.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          }

          // Show a loader while authentication state is resolving.
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
