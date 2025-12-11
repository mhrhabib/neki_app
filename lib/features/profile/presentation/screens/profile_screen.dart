import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

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
    // Material 3 plays nice with ColorScheme. Using Theme.of(context) extensively.
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar.large(
              backgroundColor: colorScheme.surface,
              surfaceTintColor: colorScheme.surfaceTint,
              expandedHeight: 120.h,
              floating: true,
              pinned: true,
              actions: [
                IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined), tooltip: 'Settings'),
                SizedBox(width: 8.w),
              ],
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: EdgeInsetsDirectional.only(start: 16.w, bottom: 16.h),
                title: Text(
                  'Profile',
                  style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    _buildProfileHeader(context),
                    SizedBox(height: 32.h),
                    _buildStatsGrid(context),
                    SizedBox(height: 32.h),
                    _buildBadgesSection(context),
                    SizedBox(height: 32.h),
                    _buildSettingsSection(context),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            Container(
              width: 120.w,
              height: 120.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                border: Border.all(color: colorScheme.primaryContainer, width: 4.w),
                image: const DecorationImage(
                  image: NetworkImage('https://api.dicebear.com/9.x/avataaars/png?seed=Habib'), // Placeholder
                  fit: BoxFit.cover,
                ), // Fallback if no image
              ),
            ),
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(color: colorScheme.surface, width: 3.w),
              ),
              child: Icon(Icons.edit, size: 16.sp, color: colorScheme.onPrimary),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        Text(
          'Habib',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
        ),
        SizedBox(height: 4.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_on_outlined, size: 16.sp, color: colorScheme.outline),
            SizedBox(width: 4.w),
            Text('Bangladesh', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.outline)),
          ],
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(color: colorScheme.tertiaryContainer, borderRadius: BorderRadius.circular(20.r)),
          child: Text(
            'Member since Nov 2025',
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: colorScheme.onTertiaryContainer, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text('Overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        SizedBox(height: 16.h),
        Row(
          children: [
            Expanded(child: _buildStatCard(context, _stats[0], isLarge: true)), // Total Neki
          ],
        ),
        SizedBox(height: 12.h),
        Row(
          children: [
            Expanded(child: _buildStatCard(context, _stats[1])), // Streak
            SizedBox(width: 12.w),
            Expanded(child: _buildStatCard(context, _stats[2])), // Days Active
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, Stat stat, {bool isLarge = false}) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: stat.color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.r),
        side: BorderSide(color: stat.color.withValues(alpha: 0.1), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(isLarge ? 20.w : 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(color: stat.color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(stat.icon, color: stat.color, size: isLarge ? 28.sp : 20.sp),
            ),
            SizedBox(height: isLarge ? 16.h : 12.h),
            Text(
              stat.value,
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                fontSize: isLarge ? 32.sp : 24.sp,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              stat.label,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Achievements',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              TextButton(onPressed: () {}, child: const Text('View All')),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        GridView.builder(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 0.85,
          ),
          itemCount: _badges.length,
          itemBuilder: (ctx, index) => _buildBadgeItem(context, _badges[index]),
        ),
      ],
    );
  }

  Widget _buildBadgeItem(BuildContext context, Badge badge) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUnlocked = badge.unlocked;

    return Column(
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? colorScheme.secondaryContainer.withValues(alpha: 0.5)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(20.r),
              border: isUnlocked ? Border.all(color: colorScheme.secondaryContainer, width: 2) : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  badge.icon,
                  style: TextStyle(
                    fontSize: 36.sp,
                    color: isUnlocked ? null : colorScheme.onSurface.withValues(alpha: 0.2),
                  ),
                ),
                if (!isUnlocked) Icon(Icons.lock, color: colorScheme.onSurface.withValues(alpha: 0.3), size: 24.sp),
              ],
            ),
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          badge.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: isUnlocked ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text('Settings', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        SizedBox(height: 16.h),
        Card(
          elevation: 0,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          child: Column(
            children: [
              _buildSettingTile(
                context,
                icon: Icons.leaderboard_outlined,
                title: 'Show on Leaderboard',
                trailing: Switch.adaptive(value: true, onChanged: (v) {}, activeThumbColor: AppColors.primaryGreen),
              ),
              Divider(height: 1, indent: 56.w, endIndent: 20.w),
              _buildSettingTile(
                context,
                icon: Icons.notifications_none_outlined,
                title: 'Notifications',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              Divider(height: 1, indent: 56.w, endIndent: 20.w),
              _buildSettingTile(
                context,
                icon: Icons.lock_outline,
                title: 'Privacy Policy',
                trailing: const Icon(Icons.chevron_right),
                onTap: () {},
              ),
              Divider(height: 1, indent: 56.w, endIndent: 20.w),
              _buildSettingTile(
                context,
                icon: Icons.logout,
                title: 'Log Out',
                titleColor: Theme.of(context).colorScheme.error,
                iconColor: Theme.of(context).colorScheme.error,
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    Widget? trailing,
    VoidCallback? onTap,
    Color? titleColor,
    Color? iconColor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.1),
          shape: BoxShape.circle,
          // border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
        ),
        child: Icon(icon, color: iconColor ?? colorScheme.primary, size: 20.sp),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500, color: titleColor ?? colorScheme.onSurface),
      ),
      trailing: trailing,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
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
