import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../points/presentation/cubit/points_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../theme/theme_cubit.dart';
import '../../../challenge/presentation/cubit/challenge_cubit.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  final List<PillarItem> _pillars = const [
    PillarItem(
      id: 'salah',
      title: 'Salah',
      icon: '🕌',
      route: RouteNames.salah,
      color: Color(0xFF0F5132),
      description: 'Track your daily prayers',
    ),
    PillarItem(
      id: 'roza',
      title: 'Roza',
      icon: '🌙',
      color: Color(0xFF6366F1),
      description: 'Track your fasting days',
      route: RouteNames.roza,
    ),
    PillarItem(id: 'zakat', title: 'Zakat', icon: '💰', color: Color(0xFFD4AF37), description: 'Coming soon'),
    PillarItem(
      id: 'Dhikir',
      title: 'Dhikir',
      icon: '🕋',
      route: RouteNames.dhikir,
      color: Color(0xFF8B5CF6),
      description: 'Dhikir counter for Hajj',
    ),
    PillarItem(
      id: 'deeds',
      title: 'Good Deeds',
      icon: '❤️',
      route: RouteNames.goodDeeds,
      color: Color(0xFFEF4444),
      description: 'Log your good actions',
    ),
    PillarItem(
      id: 'addiction',
      title: 'Addiction',
      icon: '🚫',
      route: RouteNames.addiction,
      color: Color(0xFFEF4444),
      description: 'Recovery plans & support',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : const Color(0xFFF9FAFB),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is Authenticated) {
            context.read<PointsCubit>().loadUserPoints(authState.user.id);
            context.read<ChallengeCubit>().loadChallenge(authState.user.id);

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 24.h),
                    _buildStreakCard(context, authState.user.id),
                    SizedBox(height: 20.h),
                    _buildChallengeSections(context, isDark),
                    SizedBox(height: 32.h),
                    _buildPillarsSection(context),
                  ],
                ),
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildChallengeSections(BuildContext context, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          _buildAddictionChallengeCard(context, isDark),
          SizedBox(height: 12.h),
          _buildGeneralChallengeCard(context, isDark),
        ],
      ),
    );
  }

  Widget _buildAddictionChallengeCard(BuildContext context, bool isDark) {
    return BlocBuilder<ChallengeCubit, ChallengeState>(
      builder: (context, state) {
        final hasActive =
            state is ChallengeLoaded &&
            state.hasActiveChallenge &&
            state.challenge != null &&
            state.challenge!.challengeType != null &&
            state.challenge!.challengeType!.startsWith('addiction_');

        if (hasActive) {
          final challenge = state.challenge!;
          final canCompleteToday = challenge.canCompleteToday();

          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: InkWell(
              onTap: () => context.push(RouteNames.habitBuilding),
              borderRadius: BorderRadius.circular(12.r),
              child: Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF8E24AA), Color(0xFF6A1B9A)]),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text('🚫', style: TextStyle(fontSize: 22.sp)),
                    ),
                    SizedBox(width: 14.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${challenge.durationDays}-Day Plan',
                            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.white),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'Day ${challenge.completedDays} of ${challenge.durationDays}',
                            style: TextStyle(fontSize: 13.sp, color: Colors.white.withValues(alpha: 0.8)),
                          ),
                        ],
                      ),
                    ),
                    if (!canCompleteToday)
                      Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white, size: 24.sp)
                    else
                      Icon(CupertinoIcons.chevron_right, color: Colors.white.withValues(alpha: 0.5), size: 16.sp),
                  ],
                ),
              ),
            ),
          );
        }

        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: InkWell(
            onTap: () => context.push(RouteNames.addiction),
            borderRadius: BorderRadius.circular(12.r),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF9C27B0).withValues(alpha: 0.9),
                    const Color(0xFF9C27B0).withValues(alpha: 0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Text('🚫', style: TextStyle(fontSize: 22.sp)),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Addiction Recovery',
                          style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        SizedBox(height: 2.h),
                        Text(
                          'Start a recovery plan',
                          style: TextStyle(fontSize: 13.sp, color: Colors.white.withValues(alpha: 0.8)),
                        ),
                      ],
                    ),
                  ),
                  Icon(CupertinoIcons.chevron_right, color: Colors.white.withValues(alpha: 0.5), size: 16.sp),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildGeneralChallengeCard(BuildContext context, bool isDark) {
    return BlocBuilder<ChallengeCubit, ChallengeState>(
      builder: (context, state) {
        final hasActive =
            state is ChallengeLoaded &&
            state.hasActiveChallenge &&
            (state.challenge?.challengeType == null || !state.challenge!.challengeType!.startsWith('addiction_'));

        if (hasActive) {
          final challenge = state.challenge!;
          final canCompleteToday = challenge.canCompleteToday();

          return InkWell(
            onTap: () => context.push(RouteNames.habitBuilding),
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryGreen, AppColors.primaryGreen.withValues(alpha: 0.8)],
                ),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text('🎯', style: TextStyle(fontSize: 28.sp)),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${challenge.durationDays}-Day Challenge',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 4.h),
                        Row(
                          children: [
                            Text(
                              'Day ${challenge.completedDays} of ${challenge.durationDays}',
                              style: TextStyle(fontSize: 14.sp, color: Colors.white.withValues(alpha: 0.9)),
                            ),
                            if (!canCompleteToday) ...[
                              SizedBox(width: 8.w),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                                child: Text(
                                  '✓ Done',
                                  style: TextStyle(fontSize: 10.sp, color: Colors.white, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20.sp),
                ],
              ),
            ),
          );
        }

        return InkWell(
          onTap: () => context.push(RouteNames.goalSelection),
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primaryGreen, AppColors.primaryGreen.withValues(alpha: 0.8)]),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text('🎯', style: TextStyle(fontSize: 28.sp)),
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Beat Satan Challenge',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Start building your daily neki habit',
                        style: TextStyle(fontSize: 14.sp, color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, color: Colors.white, size: 20.sp),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return BlocBuilder<ThemeCubit, ThemeData>(
      builder: (context, themeData) {
        final isDark = themeData.brightness == Brightness.dark;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 48.w), // Placeholder for balance
                  Text(
                    'Salam, Habib',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textDark,
                      letterSpacing: -0.4,
                    ),
                  ),
                  IconButton(
                    onPressed: () => context.read<ThemeCubit>().toggleTheme(),
                    icon: Icon(
                      isDark ? CupertinoIcons.sun_max_fill : CupertinoIcons.moon_fill,
                      color: isDark ? AppColors.goldAccent : AppColors.primaryGreen,
                      size: 20.sp,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 2.h),
              Text(
                'May your day be blessed',
                style: TextStyle(fontSize: 13.sp, color: isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStreakCard(BuildContext context, String userId) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: BlocBuilder<PointsCubit, PointsState>(
        builder: (context, state) {
          if (state is PointsLoaded) {
            return Container(
              padding: EdgeInsets.all(24.w),
              decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(20.r)),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(Icons.local_fire_department, color: AppColors.goldAccent, size: 24.sp),
                      SizedBox(width: 8.w),
                      Text(
                        'Current Streak',
                        style: TextStyle(fontSize: 14.sp, color: AppColors.goldAccent, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    '${state.points.todayPoints}',
                    style: TextStyle(fontSize: 48.sp, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'Neki Points Today',
                    style: TextStyle(fontSize: 16.sp, color: AppColors.goldAccent, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 16.h),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🔥', style: TextStyle(fontSize: 20.sp)),
                        SizedBox(width: 8.w),
                        Text(
                          '${state.points.currentStreak} Day Streak',
                          style: TextStyle(fontSize: 14.sp, color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          return const SizedBox();
        },
      ),
    );
  }

  Widget _buildPillarsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Five Pillars',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 16.h),
          ..._pillars.map((pillar) => _buildPillarCard(context, pillar)),
        ],
      ),
    );
  }

  Widget _buildPillarCard(BuildContext context, PillarItem pillar) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: pillar.route != null ? () => context.push(pillar.route!) : null,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: isDark ? const Color(0xFF38383A) : const Color(0xFFE5E5EA), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: pillar.color.withValues(alpha: isDark ? 0.2 : 0.15),
                borderRadius: BorderRadius.circular(14.r),
              ),
              child: Center(
                child: Text(pillar.icon, style: TextStyle(fontSize: 28.sp)),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pillar.title,
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    pillar.description,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            if (pillar.route != null)
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Center(
                  child: Text(
                    '→',
                    style: TextStyle(fontSize: 16.sp, color: isDark ? Colors.white : Colors.black),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PillarItem {
  const PillarItem({
    required this.id,
    required this.title,
    required this.icon,
    required this.color,
    required this.description,
    this.route,
  });

  final String id;
  final String title;
  final String icon;
  final Color color;
  final String description;
  final String? route;
}
