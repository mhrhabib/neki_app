import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../components/app_background_widget.dart';
import '../../../points/presentation/cubit/points_cubit.dart';
import '../../../salah/presentation/cubit/salah_cubit.dart';
import '../../../dhikir/presentation/cubit/dhikir_cubit.dart';
import '../../../auth/domain/repositories/premium_repository.dart';
import '../../../../core/di/set_up_di.dart';
import '../widgets/salah_heatmap_widget.dart';
import '../widgets/dhikr_velocity_chart.dart';
import '../widgets/salah_intensity_chart.dart';
import '../widgets/premium_locked_guard.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key});

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return;

    final now = DateTime.now();
    // Normalize to start of day for accurate counting
    final rangeStart30 = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 30));
    final rangeStart7 = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));

    // Load 30 days of history for the intensity chart
    context.read<SalahCubit>().loadSalahHistory(
      userId: uid,
      startDate: rangeStart30,
      endDate: now,
    );

    // Load Dhikr insights
    context.read<DhikirCubit>().loadDhikirInsights(
      uid,
      startDate: rangeStart7,
      endDate: now,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: getIt<PremiumRepository>().premiumStatusStream,
      initialData: getIt<PremiumRepository>().isPremiumSync(),
      builder: (context, snapshot) {
        final isPremium = snapshot.data ?? false;

        return Scaffold(
          body: Stack(
            children: [
              appBackgroundWidget(),
              SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 10.h),
                            _buildMainStats(),
                            SizedBox(height: 32.h),
                            _buildHeatmapSection(),
                            SizedBox(height: 32.h),
                            _buildInsightSection(
                              'Dhikr Velocity',
                              'Insights into your tasbih consistency over the last week.',
                              _buildDhikrVelocityChart(),
                              isPremium,
                            ),
                            SizedBox(height: 12.h),
                            _buildInsightSection(
                              'Prayer Consistency',
                              'Frequency of completions vs misses for each prayer.',
                              _buildSalahIntensityChart(),
                              isPremium,
                            ),
                            SizedBox(height: 100.h),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            'Your Spiritual Journey',
            style: GoogleFonts.sanchez(
              fontSize: 22.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStats() {
    return BlocBuilder<PointsCubit, PointsState>(
      builder: (context, pointsState) {
        int totalPoints = 0;
        int currentStreak = 0;
        if (pointsState is PointsLoaded) {
          totalPoints = pointsState.points.totalPoints;
          currentStreak = pointsState.points.currentStreak;
        }

        return Row(
          children: [
            Expanded(
              child: _buildBigStatCard(
                'Total Neki',
                totalPoints.toString(),
                '🌟',
                AppColors.goldAccent,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: _buildBigStatCard(
                'Current Streak',
                '$currentStreak Days',
                '🔥',
                Colors.orangeAccent,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBigStatCard(
    String label,
    String value,
    String emoji,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: TextStyle(fontSize: 18.sp)),
          ),
          SizedBox(height: 16.h),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: Colors.white38,
              fontSize: 10.sp,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Salah Consistency',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'Last 7 Days',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        BlocBuilder<SalahCubit, SalahState>(
          builder: (context, state) {
            if (state is SalahLoaded && state.history != null) {
              // Note: Heatmap uses the last 7 days from history
              return SalahHeatmapWidget(history: state.history!);
            }
            return _buildLoader();
          },
        ),
      ],
    );
  }

  Widget _buildInsightSection(
    String title,
    String subtitle,
    Widget chart,
    bool isPremium,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(color: Colors.white38, fontSize: 13.sp),
        ),
        SizedBox(height: 20.h),
        PremiumLockedGuard(isPremium: isPremium, title: title, child: chart),
      ],
    );
  }

  Widget _buildDhikrVelocityChart() {
    return BlocBuilder<DhikirCubit, DhikirState>(
      builder: (context, state) {
        if (state is DhikirInsightsLoaded) {
          if (state.dailyCounts.isEmpty) {
            return _buildEmptyState('No Dhikr sessions recorded in the last 7 days.');
          }
          return DhikrVelocityChart(dailyCounts: state.dailyCounts);
        } else if (state is DhikirError) {
          return _buildErrorState('Failed to load Dhikr insights: ${state.message}');
        }
        return _buildLoader();
      },
    );
  }

  Widget _buildSalahIntensityChart() {
    return BlocBuilder<SalahCubit, SalahState>(
      builder: (context, state) {
        if (state is SalahLoaded && state.history != null) {
          if (state.history!.isEmpty) {
            return _buildEmptyState('No prayer history available for the last 30 days.');
          }
          return SalahIntensityChart(history: state.history!, daysInRange: 30);
        } else if (state is SalahError) {
          return _buildErrorState('Failed to load Salah history.');
        }
        return _buildLoader();
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      height: 200.h,
      alignment: Alignment.center,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.query_stats_rounded, color: Colors.white24, size: 32.sp),
          SizedBox(height: 12.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white24, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Container(
      height: 200.h,
      alignment: Alignment.center,
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.1)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.redAccent.withValues(alpha: 0.6), fontSize: 12.sp),
      ),
    );
  }

  Widget _buildLoader() {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primaryGreen,
          strokeWidth: 2,
        ),
      ),
    );
  }
}
