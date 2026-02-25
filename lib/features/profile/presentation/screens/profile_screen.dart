import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../cubit/profile_cubit.dart';
import '../../../../components/app_background_widget.dart';

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
    Stat(
      label: 'Total Neki',
      value: '4,582',
      icon: Icons.emoji_events,
      color: Color(0xFFD4AF37),
    ),
    Stat(
      label: 'Current Streak',
      value: '7 days',
      icon: Icons.local_fire_department,
      color: Color(0xFFEF4444),
    ),
    Stat(
      label: 'Days Active',
      value: '42',
      icon: Icons.calendar_today,
      color: Color(0xFF0F5132),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          appBackgroundWidget(),
          BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) {
              if (state is Authenticated) {
                return SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: 20.h),
                    child: Column(
                      children: [
                        _buildHeader(context),
                        SizedBox(height: 20.h),
                        _buildProfileSection(context, state.user),
                        SizedBox(height: 32.h),
                        _buildSectionLabel(context, 'ACHIEVEMENTS'),
                        _buildBadgesSection(context),
                        SizedBox(height: 32.h),
                        _buildSectionLabel(context, 'STATISTICS'),
                        _buildStatsSection(context),
                        SizedBox(height: 32.h),
                        _buildSectionLabel(context, 'SETTINGS'),
                        _buildPrivacySection(context),
                        SizedBox(height: 32.h),
                        _buildLogoutButton(context),
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
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(width: 40.w), // Balance
          Text(
            'Profile',
            style: TextStyle(
              fontSize: 17.sp,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textDark,
              letterSpacing: -0.4,
            ),
          ),
          Icon(
            CupertinoIcons.settings,
            color: AppColors.primaryGreen,
            size: 22.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: EdgeInsets.only(left: 20.w, bottom: 8.h),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF8E8E93),
            letterSpacing: -0.07,
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, UserEntity user) {
    return Column(
      children: [
        // Profile Image
        GestureDetector(
          onTap: () => _showImageSourcePicker(context, user.id),
          child: Stack(
            children: [
              BlocBuilder<ProfileCubit, ProfileState>(
                builder: (context, state) {
                  final isLoading = state is ProfileLoading;
                  String? updatedPhotoUrl;
                  if (state is ProfileUpdated) {
                    updatedPhotoUrl = state.photoUrl;
                  }

                  return Container(
                    width: 90.w,
                    height: 90.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFD4AF37),
                      shape: BoxShape.circle,
                      image: (updatedPhotoUrl ?? user.photoUrl) != null
                          ? DecorationImage(
                              image: NetworkImage(
                                updatedPhotoUrl ?? user.photoUrl!,
                              ),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: (updatedPhotoUrl ?? user.photoUrl) == null
                        ? Center(
                            child: isLoading
                                ? const CupertinoActivityIndicator(
                                    color: Colors.white,
                                  )
                                : Text(
                                    user.name.isNotEmpty
                                        ? user.name[0].toUpperCase()
                                        : '👤',
                                    style: TextStyle(
                                      fontSize: 40.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                          )
                        : (isLoading
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: CupertinoActivityIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                )
                              : null),
                  );
                },
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: const BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    CupertinoIcons.camera_fill,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        // User Name
        Text(
          user.name.isNotEmpty ? user.name : 'User',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        SizedBox(height: 4.h),
        // User Email
        Text(
          user.email,
          style: TextStyle(fontSize: 15.sp, color: const Color(0xFF8E8E93)),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      width: double.infinity,
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10.r),
        onPressed: () {
          _showLogoutDialog(context);
        },
        child: Text(
          'Logout',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: const Color(0xFFFF3B30),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthCubit>().logout();
              context.go(RouteNames.login);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8),
          width: 0.5,
        ),
      ),
      child: Column(
        children: List.generate(_stats.length, (index) {
          final showDivider = index < _stats.length - 1;
          return Column(
            children: [
              _buildStatItem(context, _stats[index]),
              if (showDivider)
                Padding(
                  padding: EdgeInsets.only(left: 64.w),
                  child: Divider(
                    height: 1,
                    thickness: 0.5,
                    color: isDark
                        ? const Color(0xFF38383A)
                        : const Color(0xFFC6C6C8),
                  ),
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildStatItem(BuildContext context, Stat stat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(12.w),
      child: Row(
        children: [
          Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(stat.icon, color: stat.color, size: 18.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              stat.label,
              style: TextStyle(
                fontSize: 16.sp,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
          ),
          Text(
            stat.value,
            style: TextStyle(fontSize: 16.sp, color: const Color(0xFF8E8E93)),
          ),
          SizedBox(width: 4.w),
          Icon(
            CupertinoIcons.chevron_right,
            color: const Color(0xFFC7C7CC),
            size: 14.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8),
          width: 0.5,
        ),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
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
    );
  }

  Widget _buildBadgeItem(BuildContext context, Badge badge) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      opacity: badge.unlocked ? 1.0 : 0.4,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(badge.icon, style: TextStyle(fontSize: 24.sp)),
          SizedBox(height: 4.h),
          Text(
            badge.title,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w400,
              color: isDark ? Colors.white : AppColors.textDark,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacySection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(
          color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Show on Leaderboard',
              style: TextStyle(
                fontSize: 16.sp,
                color: isDark ? Colors.white : AppColors.textDark,
              ),
            ),
            Transform.scale(
              scale: 0.8,
              child: CupertinoSwitch(
                value: true,
                activeTrackColor: AppColors.primaryGreen,
                onChanged: (val) {},
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageSourcePicker(BuildContext context, String userId) {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: const Text('Profile Picture'),
        message: const Text('Choose a source for your profile picture'),
        actions: [
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(context, userId, ImageSource.camera);
            },
            child: const Text('Camera'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(context);
              _pickImage(context, userId, ImageSource.gallery);
            },
            child: const Text('Photo Library'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _pickImage(
    BuildContext context,
    String userId,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );

    if (pickedFile != null && context.mounted) {
      context.read<ProfileCubit>().uploadProfileImage(
        userId,
        File(pickedFile.path),
      );
    }
  }
}

class Badge {
  const Badge({
    required this.id,
    required this.icon,
    required this.title,
    required this.unlocked,
  });

  final int id;
  final String icon;
  final String title;
  final bool unlocked;
}

class Stat {
  const Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}
