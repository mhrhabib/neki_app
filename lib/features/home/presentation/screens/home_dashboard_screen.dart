import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../points/presentation/cubit/points_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  final List<PillarItem> _pillars = const [
    PillarItem(
      id: 'salah',
      title: 'Salah',
      icon: '🕌',
      route: '/salah',
      color: Color(0xFF0F5132),
      description: 'Track your daily prayers',
    ),
    PillarItem(id: 'roza', title: 'Roza', icon: '🌙', color: Color(0xFF6366F1), description: 'Coming soon'),
    PillarItem(id: 'zakat', title: 'Zakat', icon: '💰', color: Color(0xFFD4AF37), description: 'Coming soon'),
    PillarItem(id: 'hajj', title: 'Hajj', icon: '🕋', color: Color(0xFF8B5CF6), description: 'Coming soon'),
    PillarItem(
      id: 'deeds',
      title: 'Good Deeds',
      icon: '❤️',
      route: '/good-deeds',
      color: Color(0xFFEF4444),
      description: 'Log your good actions',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is Authenticated) {
            context.read<PointsCubit>().loadUserPoints(authState.user.id);

            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 20.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    SizedBox(height: 24.h),
                    _buildStreakCard(context, authState.user.id),
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

  Widget _buildHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Salam, Habib',
            style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w700, color: AppColors.primaryGreen),
          ),
          SizedBox(height: 4.h),
          Text(
            'May your day be blessed',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF6B7280)),
          ),
        ],
      ),
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
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Five Pillars',
            style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700, color: const Color(0xFF1F2937)),
          ),
          SizedBox(height: 16.h),
          ..._pillars.map((pillar) => _buildPillarCard(context, pillar)),
        ],
      ),
    );
  }

  Widget _buildPillarCard(BuildContext context, PillarItem pillar) {
    return GestureDetector(
      onTap: pillar.route != null ? () => context.push(pillar.route!) : null,
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), offset: Offset(0, 1.h), blurRadius: 2.r)],
        ),
        child: Row(
          children: [
            Container(
              width: 56.w,
              height: 56.w,
              decoration: BoxDecoration(
                color: pillar.color.withValues(alpha: 0.15),
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
                    style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937)),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    pillar.description,
                    style: TextStyle(fontSize: 13.sp, color: const Color(0xFF6B7280)),
                  ),
                ],
              ),
            ),
            if (pillar.route != null)
              Container(
                width: 32.w,
                height: 32.w,
                decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(8.r)),
                child: Center(
                  child: Text('→', style: TextStyle(fontSize: 16.sp)),
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
