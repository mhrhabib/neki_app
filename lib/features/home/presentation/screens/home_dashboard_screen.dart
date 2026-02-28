import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../components/app_background_widget.dart';
import '../../../../core/location/cubit/location_cubit.dart';
import '../../../../core/location/cubit/location_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../challenge/presentation/cubit/challenge_cubit.dart';
import '../../../points/presentation/cubit/points_cubit.dart';
import '../widgets/home_all_menu_section.dart';
import '../widgets/home_current_prayer_section.dart';
import '../widgets/home_feature_cards.dart';
import '../widgets/home_user_stats_card.dart';
import '../widgets/home_prayer_times_row.dart';
import '../widgets/home_top_bar.dart';

/// Home dashboard screen.
///
/// Acts as an orchestrator: it wires up Blocs/Cubits and hands off
/// the individual UI sections to self-contained widget files found in
/// `lib/features/home/presentation/widgets/`.
class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

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
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is Authenticated) {
            // Trigger data loads as soon as we know the user.
            context.read<PointsCubit>().loadUserPoints(authState.user.id);
            context.read<ChallengeCubit>().loadChallenge(authState.user.id);

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
