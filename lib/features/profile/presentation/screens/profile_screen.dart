import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  final List<Badge> _badges = const [
    Badge(id: 1, icon: '🌟', title: 'First Prayer', unlocked: true),
    Badge(id: 2, icon: '🔥', title: '7 Day Streak', unlocked: true),
    Badge(id: 3, icon: '💯', title: '100 Neki', unlocked: true),
    Badge(id: 4, icon: '📿', title: 'Dhikr Master', unlocked: false),
    Badge(id: 5, icon: '🏆', title: 'Top 10', unlocked: false),
    Badge(id: 6, icon: '⭐', title: '30 Day Streak', unlocked: false),
  ];

  final List<Stat> _stats = const [
    Stat(label: 'Total Neki', value: '4,582', icon: Icons.emoji_events, color: Color(0xFFD4AF37)),
    Stat(label: 'Current Streak', value: '7 days', icon: Icons.local_fire_department, color: Color(0xFFEF4444)),
    Stat(label: 'Days Active', value: '42', icon: Icons.calendar_today, color: Color(0xFF0F5132)),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : const Color(0xFFF9FAFB),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is Authenticated) {
            return SafeArea(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(bottom: 20.h),
                child: Column(
                  spacing: 12,
                  children: [
                    _buildHeader(),
                    _buildProfileSection(state.user),
                    _buildLogoutButton(context),
                    _buildStatsSection(context),
                    _buildBadgesSection(context),
                    _buildPrivacySection(context),
                  ],
                ),
              ),
            );
          }

          return SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    'Not logged in',
                    style: TextStyle(fontSize: 18.sp, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(color: AppColors.primaryGreen),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Profile',
            style: TextStyle(fontSize: 28.sp, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.settings, color: Colors.white, size: 20.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(user) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      color: AppColors.primaryGreen,
      child: Column(
        children: [
          // Profile Image
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: const Color(0xFFD4AF37),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 4.w),
              image: user.photoUrl != null
                  ? DecorationImage(image: NetworkImage(user.photoUrl!), fit: BoxFit.cover)
                  : null,
            ),
            child: user.photoUrl == null
                ? Center(
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '👤',
                      style: TextStyle(fontSize: 48.sp, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  )
                : null,
          ),
          SizedBox(height: 16.h),
          // User Name
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  user.name.isNotEmpty ? user.name : 'User',
                  style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w700, color: Colors.white),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          // User Email
          Text(
            user.email,
            style: TextStyle(fontSize: 14.sp, color: Colors.white.withValues(alpha: 0.9), fontWeight: FontWeight.w400),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 4.h),
          // Member Since
          Text(
            'Member since ${_formatDate(user.createdAt)}',
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFFD4AF37), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.year}';
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      child: ElevatedButton(
        onPressed: () {
          // Show confirmation dialog
          showDialog(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                    context.read<AuthCubit>().logout();
                    context.go(RouteNames.login);
                  },
                  child: const Text('Logout', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, size: 20.sp),
            SizedBox(width: 8.w),
            Text(
              'Logout',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      ),
      child: Column(children: _stats.map((stat) => _buildStatItem(context, stat)).toList()),
    );
  }

  Widget _buildStatItem(BuildContext context, Stat stat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: isDark ? 0.25 : 0.15),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(stat.icon, color: stat.color, size: 22.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.label,
                  style: TextStyle(fontSize: 13.sp, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
                ),
                SizedBox(height: 2.h),
                Text(
                  stat.value,
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 24.h),
          Text(
            'Badges & Achievements',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 16.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 1,
            ),
            itemCount: _badges.length,
            itemBuilder: (ctx, index) => _buildBadgeItem(context, _badges[index]),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeItem(BuildContext context, Badge badge) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: badge.unlocked ? AppColors.primaryGreen : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
        ),
      ),
      child: Opacity(
        opacity: badge.unlocked ? 1.0 : 0.5,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(badge.icon, style: TextStyle(fontSize: 28.sp)),
            SizedBox(height: 6.h),
            Text(
              badge.title,
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
                color: badge.unlocked ? (isDark ? Colors.white : const Color(0xFF1F2937)) : const Color(0xFF9CA3AF),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Privacy Settings',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : const Color(0xFF1F2937),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Show on Leaderboard',
                style: TextStyle(fontSize: 14.sp, color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280)),
              ),
              Container(
                width: 50.w,
                height: 30.h,
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(15.r)),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    width: 26.w,
                    height: 26.w,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Badge {
  const Badge({required this.id, required this.icon, required this.title, required this.unlocked});

  final int id;
  final String icon;
  final String title;
  final bool unlocked;
}

class Stat {
  const Stat({required this.label, required this.value, required this.icon, required this.color});

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}
