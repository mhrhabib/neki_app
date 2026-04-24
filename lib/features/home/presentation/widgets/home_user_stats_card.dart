import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:neki_app/core/routes/route_names.dart';
import 'package:neki_app/features/home/presentation/widgets/salah_heatmap_widget.dart';
import 'package:neki_app/features/salah/presentation/cubit/salah_cubit.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../points/presentation/cubit/points_cubit.dart';

/// A modern, glassmorphic card that displays the user's Neki points
/// and their current prayer streak.
class HomeUserStatsCard extends StatefulWidget {
  const HomeUserStatsCard({super.key});

  @override
  State<HomeUserStatsCard> createState() => _HomeUserStatsCardState();
}

class _HomeUserStatsCardState extends State<HomeUserStatsCard> {
  /// Ensures we only fire one history refresh per "history is null" event,
  /// not on every BlocBuilder rebuild.
  bool _historyRefreshScheduled = false;

  /// Called whenever we detect that state is SalahLoaded but history == null.
  /// Uses post-frame so we never call setState/emit during build.
  void _scheduleHistoryLoad() {
    if (_historyRefreshScheduled) return;
    _historyRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _historyRefreshScheduled = false;
      final authState = context.read<AuthCubit>().state;
      if (authState is! Authenticated) return;
      context.read<SalahCubit>().loadSalahHistory(
        userId: authState.user.id,
        startDate: DateTime.now().subtract(const Duration(days: 7)),
        endDate: DateTime.now(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: BlocBuilder<PointsCubit, PointsState>(
        builder: (context, state) {
          int totalPoints = 0;
          int currentStreak = 0;

          if (state is PointsLoaded) {
            totalPoints = state.points.totalPoints;
            currentStreak = state.points.currentStreak;
            debugPrint(
              'Total Points: $totalPoints, Current Streak: $currentStreak',
            );
          }

          return GestureDetector(
            onTap: () => context.push(RouteNames.journey),
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      // --- Neki Points Section ---
                      _StatItem(
                        label: 'TOTAL NEKI',
                        value: totalPoints.toString(),
                        icon: '🌟',
                        accentColor: AppColors.goldAccent,
                      ),

                      // Vertical Divider
                      Container(
                        height: 40.h,
                        width: 1.w,
                        color: Colors.white10,
                        margin: EdgeInsets.symmetric(horizontal: 20.w),
                      ),

                      // --- Streak Section ---
                      _StatItem(
                        label: 'CURR. STREAK',
                        value: '$currentStreak Days',
                        icon: '🔥',
                        accentColor: Colors.orangeAccent,
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  const Divider(color: Colors.white10, height: 1),
                  SizedBox(height: 16.h),
                  BlocBuilder<SalahCubit, SalahState>(
                    builder: (context, salahState) {
                      // ✅ Heatmap is ready — render it.
                      if (salahState is SalahLoaded &&
                          salahState.history != null) {
                        return SalahHeatmapWidget(
                          history: salahState.history!,
                          isCompact: true,
                        );
                      }

                      // ⚠️ State is loaded but history wasn't fetched (e.g. after
                      // returning from Salah lock overlay which only calls
                      // loadTodaysSalahs). Schedule a history reload automatically.
                      if (salahState is SalahLoaded &&
                          salahState.history == null) {
                        _scheduleHistoryLoad();
                      }

                      // Show a spinner while history is loading or being re-fetched.
                      return Container(
                        height: 60.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              color: Colors.white24,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  final Color accentColor;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: TextStyle(fontSize: 16.sp)),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }
}
