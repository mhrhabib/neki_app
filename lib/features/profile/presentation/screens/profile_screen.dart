import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/widgets/custom_icon_button.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/domain/entities/user_entity.dart';
import '../../../points/domain/entities/neki_points_entity.dart';
import '../../domain/entities/badge_entity.dart';
import '../cubit/profile_cubit.dart';
import '../../../../components/app_background_widget.dart';
import '../../../../core/di/set_up_di.dart';
import '../../../auth/domain/repositories/premium_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      final authState = context.read<AuthCubit>().state;
      if (authState is Authenticated) {
        context.read<ProfileCubit>().loadProfile(authState.user.id, createdAt: authState.user.createdAt);
      }
    }
  }

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
                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 120.h,
                      pinned: true,
                      stretch: true,
                      backgroundColor: Colors.transparent,
                      surfaceTintColor: Colors.transparent,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        centerTitle: true,
                        title: Text(
                          'My Profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ),
                      actions: [
                        CustomIconButton(
                          icon: CupertinoIcons.settings,
                          onPressed: () {},
                          baseColor: AppColors.primaryGreen,
                          size: 44,
                          padding: EdgeInsets.only(right: 16.w),
                        ),
                      ],
                    ),
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          SizedBox(height: 10.h),
                          _buildProfileSection(context, state.user),
                          SizedBox(height: 16.h),
                          _buildPremiumCard(context),
                          SizedBox(height: 24.h),
                          _buildStatsSection(context),
                          SizedBox(height: 40.h),
                          _buildSectionLabel(context, 'ACHIEVEMENTS'),
                          _buildBadgesSection(context),
                          SizedBox(height: 40.h),
                          _buildSectionLabel(context, 'ACCOUNT SETTINGS'),
                          _buildPrivacySection(context, state.user.id),
                          SizedBox(height: 16.h),
                          _buildLogoutButton(context),
                          SizedBox(height: 100.h),
                        ],
                      ),
                    ),
                  ],
                );
              }

              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_off, size: 64.sp, color: Colors.white24),
                    SizedBox(height: 16.h),
                    Text(
                      'Not logged in',
                      style: TextStyle(fontSize: 18.sp, color: Colors.white54),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: EdgeInsets.fromLTRB(25.w, 0, 0, 15.h),
      child: Row(
        children: [
          Container(
            width: 3.w,
            height: 14.h,
            decoration: BoxDecoration(color: AppColors.goldAccent, borderRadius: BorderRadius.circular(2.r)),
          ),
          SizedBox(width: 10.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.goldAccent,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(BuildContext context, UserEntity user) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showImageSourcePicker(context, user.id),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 110.w,
                height: 110.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.3), width: 2.w),
                ),
              ),
              BlocBuilder<ProfileCubit, ProfileState>(
                buildWhen: (prev, curr) =>
                    curr is ProfileLoading || curr is ProfilePhotoUpdated || curr is ProfileLoaded,
                builder: (context, state) {
                  final isLoading = state is ProfileLoading;
                  String? updatedPhotoUrl;
                  if (state is ProfilePhotoUpdated) {
                    updatedPhotoUrl = state.photoUrl;
                  }

                  return Container(
                    width: 95.w,
                    height: 95.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      shape: BoxShape.circle,
                      image: (updatedPhotoUrl ?? user.photoUrl) != null
                          ? DecorationImage(image: NetworkImage(updatedPhotoUrl ?? user.photoUrl!), fit: BoxFit.cover)
                          : null,
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2.w),
                    ),
                    child: (updatedPhotoUrl ?? user.photoUrl) == null
                        ? Center(
                            child: isLoading
                                ? const CupertinoActivityIndicator(color: Colors.white)
                                : Text(
                                    user.name.isNotEmpty ? user.name[0].toUpperCase() : '👤',
                                    style: TextStyle(
                                      fontSize: 35.sp,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white24,
                                    ),
                                  ),
                          )
                        : (isLoading
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(child: CupertinoActivityIndicator(color: Colors.grey)),
                                )
                              : null),
                  );
                },
              ),
              Positioned(
                bottom: 5.h,
                right: 5.w,
                child: Container(
                  padding: EdgeInsets.all(6.w),
                  decoration: BoxDecoration(
                    color: AppColors.primaryGreen,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black, width: 2.w),
                  ),
                  child: Icon(CupertinoIcons.camera_fill, color: Colors.white, size: 14.sp),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 16.h),
        Text(
          user.name.isNotEmpty ? user.name : 'Seeker of Neki',
          style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
        ),
        SizedBox(height: 4.h),
        Text(
          user.email,
          style: TextStyle(fontSize: 14.sp, color: Colors.white38, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPremiumCard(BuildContext context) {
    // Access the PremiumRepository directly via Service Locator
    final premiumRepo = getIt<PremiumRepository>();
    final isPremium = premiumRepo.isPremiumSync();
    final isTrial = premiumRepo.isTrialActiveSync();
    final daysLeft = premiumRepo.trialDaysRemainingSync();

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: GestureDetector(
        onTap: isPremium && !isTrial
            ? null
            : () => context.push(RouteNames.premium),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPremium && !isTrial
                  ? [
                      const Color(0xFFD4AF37).withValues(alpha: 0.2),
                      const Color(0xFFD4AF37).withValues(alpha: 0.1),
                    ]
                  : [
                      AppColors.primaryGreen.withValues(alpha: 0.15),
                      AppColors.primaryGreen.withValues(alpha: 0.05),
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: isPremium && !isTrial
                  ? AppColors.goldAccent.withValues(alpha: 0.3)
                  : AppColors.primaryGreen.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: isPremium && !isTrial
                      ? AppColors.goldAccent.withValues(alpha: 0.15)
                      : AppColors.primaryGreen.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isPremium && !isTrial
                      ? Icons.workspace_premium_rounded
                      : Icons.star_rounded,
                  color: isPremium && !isTrial
                      ? AppColors.goldAccent
                      : AppColors.primaryGreen,
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPremium && !isTrial
                          ? 'NEKI PREMIUM'
                          : isTrial
                              ? 'PREMIUM TRIAL'
                              : 'UPGRADE TO PRO',
                      style: TextStyle(
                        color: isPremium && !isTrial
                            ? AppColors.goldAccent
                            : Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      isPremium && !isTrial
                          ? 'Active Member'
                          : isTrial
                              ? '$daysLeft days remaining'
                              : 'Unlock insights & 5x locks',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isPremium || isTrial)
                Icon(
                  CupertinoIcons.chevron_right,
                  color: Colors.white24,
                  size: 16.sp,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      buildWhen: (prev, curr) => curr is ProfileLoaded || curr is ProfileLoading || curr is ProfileError,
      builder: (context, state) {
        if (state is ProfileLoaded) {
          return _buildStatsHorizontal(context, state.stats, state.daysActive);
        }
        if (state is ProfileError) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              'Could not load stats',
              style: TextStyle(color: Colors.white38, fontSize: 14.sp),
            ),
          );
        }
        // Loading or initial
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: const CupertinoActivityIndicator(color: Colors.white24),
        );
      },
    );
  }

  Widget _buildStatsHorizontal(BuildContext context, NekiPointsEntity stats, int daysActive) {
    final statItems = [
      _StatItem(
        label: 'Total Neki',
        value: _formatNumber(stats.totalPoints),
        icon: Icons.emoji_events,
        color: const Color(0xFFD4AF37),
      ),
      _StatItem(
        label: 'Current Streak',
        value: '${stats.currentStreak} days',
        icon: Icons.local_fire_department,
        color: const Color(0xFFEF4444),
      ),
      _StatItem(label: 'Days Active', value: '$daysActive', icon: Icons.calendar_today, color: const Color(0xFF0F5132)),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(children: statItems.map((stat) => _buildStatCard(context, stat)).toList()),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }

  Widget _buildStatCard(BuildContext context, _StatItem stat) {
    return Container(
      width: 140.w,
      margin: EdgeInsets.only(right: 12.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: stat.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(stat.icon, color: stat.color, size: 20.sp),
          ),
          SizedBox(height: 16.h),
          Text(
            stat.value,
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w900, color: Colors.white),
          ),
          Text(
            stat.label.toUpperCase(),
            style: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w800, color: Colors.white38, letterSpacing: 0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      buildWhen: (prev, curr) => curr is ProfileLoaded || curr is ProfileLoading || curr is ProfileError,
      builder: (context, state) {
        if (state is ProfileLoaded) {
          return _buildBadgesGrid(context, state.badges);
        }
        if (state is ProfileError) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Text(
              'Could not load badges',
              style: TextStyle(color: Colors.white38, fontSize: 14.sp),
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 20.h),
          child: const CupertinoActivityIndicator(color: Colors.white24),
        );
      },
    );
  }

  Widget _buildBadgesGrid(BuildContext context, List<BadgeEntity> badges) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: GridView.builder(
        shrinkWrap: true,
        padding: EdgeInsets.zero,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 15.w,
          mainAxisSpacing: 15.h,
          childAspectRatio: 0.85,
        ),
        itemCount: badges.length,
        itemBuilder: (ctx, index) => _buildBadgeItem(context, badges[index]),
      ),
    );
  }

  Widget _buildBadgeItem(BuildContext context, BadgeEntity badge) {
    return Container(
      decoration: BoxDecoration(
        color: badge.isEarned ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
        borderRadius: BorderRadius.circular(20.r),
        border: badge.isEarned ? Border.all(color: AppColors.goldAccent.withValues(alpha: 0.1)) : null,
      ),
      child: Opacity(
        opacity: badge.isEarned ? 1.0 : 0.2,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(badge.iconUrl, style: TextStyle(fontSize: 30.sp)),
            SizedBox(height: 8.h),
            Text(
              badge.name,
              style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w700, color: Colors.white),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacySection(BuildContext context, String userId) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      buildWhen: (prev, curr) => curr is ProfileLoaded,
      builder: (context, state) {
        final showOnLeaderboard = state is ProfileLoaded ? state.showOnLeaderboard : true;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w),
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: ListTile(
            leading: Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AppColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(CupertinoIcons.eye_fill, color: AppColors.primaryGreen, size: 18.sp),
            ),
            title: Text(
              'Show on Leaderboard',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            subtitle: Text(
              'Allow others to see your progress',
              style: TextStyle(fontSize: 12.sp, color: Colors.white38),
            ),
            trailing: CupertinoSwitch(
              value: showOnLeaderboard,
              activeTrackColor: AppColors.primaryGreen,
              onChanged: (val) {
                context.read<ProfileCubit>().updateLeaderboardVisibility(userId, val);
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      width: double.infinity,
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        color: const Color(0xFFFF3B30).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20.r),
        onPressed: () => _showLogoutDialog(context),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.power, color: const Color(0xFFFF3B30), size: 18.sp),
            SizedBox(width: 10.w),
            Text(
              'Logout Account',
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w800, color: const Color(0xFFFF3B30)),
            ),
          ],
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
          CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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

  Future<void> _pickImage(BuildContext context, String userId, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, maxWidth: 512, maxHeight: 512, imageQuality: 75);

    if (pickedFile != null && context.mounted) {
      context.read<ProfileCubit>().uploadProfileImage(userId, File(pickedFile.path));
    }
  }
}

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatItem({required this.label, required this.value, required this.icon, required this.color});
}
