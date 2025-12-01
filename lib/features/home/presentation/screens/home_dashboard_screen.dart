import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../points/presentation/cubit/points_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softCream,
      appBar: AppBar(title: Text('NEKI TRACKER', style: AppTypography.h2), centerTitle: true),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is Authenticated) {
            context.read<PointsCubit>().loadUserPoints(authState.user.id);

            return SingleChildScrollView(
              padding: EdgeInsets.all(AppSpacing.outerPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPointsCard(context, authState.user.id),
                  SizedBox(height: AppSpacing.gridGap * 2),
                  Text('Your Activities', style: AppTypography.h2),
                  SizedBox(height: AppSpacing.gridGap),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: AppSpacing.gridGap,
                    crossAxisSpacing: AppSpacing.gridGap,
                    children: [
                      _buildFeatureCard(context, '🕌', 'Salah', '/salah'),
                      _buildFeatureCard(context, '🌙', 'Roza', '/roza'),
                      _buildFeatureCard(context, '💰', 'Zakat', '/zakat'),
                      _buildFeatureCard(context, '❤️', 'Good Deeds', '/good-deeds'),
                    ],
                  ),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primaryGreen,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Leaderboard'),
        ],
        onTap: (index) {
          if (index == 1) context.push('/profile');
          if (index == 2) context.push('/leaderboard');
        },
      ),
    );
  }

  Widget _buildPointsCard(BuildContext context, String userId) {
    return BlocBuilder<PointsCubit, PointsState>(
      builder: (context, state) {
        if (state is PointsLoaded) {
          return Container(
            padding: EdgeInsets.all(AppSpacing.cardPadding * 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.primaryGreen, AppColors.darkGreen]),
              borderRadius: BorderRadius.circular(AppSpacing.cornerRadius),
            ),
            child: Column(
              children: [
                Text('Total Neki Points', style: AppTypography.body.copyWith(color: Colors.white70)),
                SizedBox(height: 8.h),
                Text(
                  '${state.points.totalPoints}',
                  style: AppTypography.h1.copyWith(color: Colors.white, fontSize: 48.sp),
                ),
                SizedBox(height: AppSpacing.gridGap),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStat('Today', state.points.todayPoints),
                    _buildStat('Streak', state.points.currentStreak),
                  ],
                ),
              ],
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildStat(String label, int value) {
    return Column(
      children: [
        Text(label, style: AppTypography.caption.copyWith(color: Colors.white70)),
        Text('$value', style: AppTypography.h2.copyWith(color: Colors.white)),
      ],
    );
  }

  Widget _buildFeatureCard(BuildContext context, String icon, String title, String route) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: EdgeInsets.all(AppSpacing.cardPadding),
        decoration: BoxDecoration(
          color: AppColors.cardWhite,
          borderRadius: BorderRadius.circular(AppSpacing.cornerRadius),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10.r, offset: Offset(0, 4.h))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(icon, style: TextStyle(fontSize: 48.sp)),
            SizedBox(height: 8.h),
            Text(title, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
