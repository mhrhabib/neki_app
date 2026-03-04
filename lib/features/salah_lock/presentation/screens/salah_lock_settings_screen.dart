import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../components/app_background_widget.dart';
import '../cubit/salah_lock_cubit.dart';

class SalahLockSettingsScreen extends StatelessWidget {
  const SalahLockSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          appBackgroundWidget(),
          BlocBuilder<SalahLockCubit, SalahLockState>(
            builder: (context, state) {
              if (state is SalahLockLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final cubit = context.read<SalahLockCubit>();
              final settings = state.settings;

              return CustomScrollView(
                slivers: [
                  SliverAppBar(
                    expandedHeight: kToolbarHeight,
                    pinned: true,
                    backgroundColor: Colors.transparent,
                    surfaceTintColor: Colors.transparent,
                    elevation: 0,
                    leadingWidth: 70.w,
                    leading: Padding(
                      padding: EdgeInsets.only(left: 16.w, top: 8.h, bottom: 8.h),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.chevron_left, size: 24.sp, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                        ),
                      ),
                    ),
                    centerTitle: true,
                    title: Text(
                      'Salah Lock Control',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: EdgeInsets.all(20.w),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSectionHeader('CORE CONFIGURATION'),
                        _buildToggleTile(
                          icon: CupertinoIcons.lock_shield_fill,
                          title: 'Enable Salah Lock Mode',
                          subtitle: 'Globally lock the app during prayer times',
                          value: settings.isEnabled,
                          onChanged: (val) => cubit.updateSettings(settings.copyWith(isEnabled: val)),
                        ),
                        SizedBox(height: 24.h),
                        _buildSectionHeader('PLATFORM PROTECTION'),
                        _buildToggleTile(
                          icon: Icons.android_rounded,
                          title: 'Lock Device Screen',
                          subtitle: 'Physically lock the device (Android Admin)',
                          value: settings.lockDeviceAndroid,
                          onChanged: (val) async {
                            if (val) {
                              final isActive = await cubit.deviceManager.isDeviceAdminActive();
                              if (!isActive) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enable Device Administrator permission, then toggle again.',
                                      ),
                                    ),
                                  );
                                }
                                await cubit.deviceManager.requestDeviceAdmin();
                                return;
                              }
                            }
                            cubit.updateSettings(settings.copyWith(lockDeviceAndroid: val));
                          },
                        ),
                        _buildToggleTile(
                          icon: Icons.app_blocking_rounded,
                          title: 'Block Distracting Apps',
                          subtitle: settings.blockedApps.isEmpty
                              ? 'Blocks social media & games during prayer'
                              : 'Blocking ${settings.blockedApps.length} social media apps',
                          value: settings.blockedApps.isNotEmpty,
                          onChanged: (val) async {
                            if (val) {
                              // 1. Turn it on in the UI immediately
                              final apps = [
                                'com.facebook.katana',
                                'com.facebook.lite',
                                'com.instagram.android',
                                'com.zhiliaoapp.musically',
                                'com.twitter.android',
                                'com.snapchat.android',
                                'com.google.android.youtube',
                                'com.google.android.apps.youtube.music',
                                'com.whatsapp',
                                'com.netflix.mediaclient',
                              ];
                              cubit.updateSettings(settings.copyWith(blockedApps: apps));

                              // 2. Request permissions in background
                              final granted = await cubit.checkAndRequestAndroidPermissions();
                              if (!granted && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Permissions required for blocking to take effect.'),
                                    duration: Duration(seconds: 3),
                                  ),
                                );
                              }
                            } else {
                              cubit.updateSettings(settings.copyWith(blockedApps: []));
                            }
                          },
                        ),
                        _buildToggleTile(
                          icon: Icons.gpp_maybe_rounded,
                          title: 'Strict Lockdown Mode',
                          subtitle: 'Lock EVERYTHING except Neki during prayer',
                          value: settings.lockAllApps,
                          onChanged: (val) async {
                            if (val) {
                              final granted = await cubit.checkAndRequestAndroidPermissions();
                              if (!granted && context.mounted) {
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(const SnackBar(content: Text('Permissions required for Lockdown.')));
                              }
                            }
                            cubit.updateSettings(settings.copyWith(lockAllApps: val));
                          },
                        ),
                        _buildToggleTile(
                          icon: Icons.apple_rounded,
                          title: 'Auto-Lock (iOS)',
                          subtitle: 'Screen Time integration for iOS limits',
                          value: settings.autoLockSocialIos,
                          onChanged: (val) async {
                            if (val) {
                              await cubit.deviceManager.requestIOSAuthorization();
                              final urls = [
                                Uri.parse('App-Prefs:root=SCREEN_TIME'),
                                Uri.parse('prefs:root=SCREEN_TIME'),
                              ];
                              for (var url in urls) {
                                if (await canLaunchUrl(url)) {
                                  await launchUrl(url);
                                  break;
                                }
                              }
                            }
                            cubit.updateSettings(settings.copyWith(autoLockSocialIos: val));
                          },
                        ),
                        SizedBox(height: 24.h),
                        _buildSectionHeader('ADVANCED FEATURES'),
                        _buildToggleTile(
                          icon: CupertinoIcons.chart_bar_fill,
                          title: 'Streak Tracking',
                          subtitle: 'Monitor your prayer consistency over time',
                          value: settings.streakTracking,
                          onChanged: (val) => cubit.updateSettings(settings.copyWith(streakTracking: val)),
                        ),
                        _buildActionTile(
                          icon: CupertinoIcons.timer_fill,
                          title: 'Auto-Unlock Buffer',
                          subtitle: 'Unlock after ${settings.autoUnlockMinutes} minutes',
                          onTap: () {
                            // Picker logic
                          },
                        ),
                        SizedBox(height: 40.h),
                      ]),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(5.w, 0, 0, 15.h),
      child: Row(
        children: [
          Container(
            width: 3.w,
            height: 14.h,
            decoration: BoxDecoration(color: AppColors.goldAccent, borderRadius: BorderRadius.circular(2.r)),
          ),
          SizedBox(width: 10.w),
          Text(
            title,
            style: TextStyle(
              color: AppColors.goldAccent,
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: AppColors.primaryGreen, size: 20.sp),
        ),
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white60, fontSize: 12.sp),
        ),
        trailing: CupertinoSwitch(
          activeTrackColor: AppColors.primaryGreen,
          inactiveTrackColor: Colors.white10,
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColors.goldAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: AppColors.goldAccent, size: 20.sp),
        ),
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white60, fontSize: 12.sp),
        ),
        trailing: Icon(CupertinoIcons.chevron_right, color: Colors.white24, size: 16.sp),
      ),
    );
  }
}
