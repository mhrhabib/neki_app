import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
                          subtitle: 'Prayer notifications + in-app reminder at each Salah time',
                          value: settings.isEnabled,
                          onChanged: (val) async {
                            if (val && Platform.isAndroid) {
                              await cubit.checkAndRequestBasicPermissions();
                            }
                            cubit.updateSettings(settings.copyWith(isEnabled: val));
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
        title: Text(title, style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.white60, fontSize: 12.sp)),
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
        title: Text(title, style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: TextStyle(color: Colors.white60, fontSize: 12.sp)),
        trailing: Icon(CupertinoIcons.chevron_right, color: Colors.white24, size: 16.sp),
      ),
    );
  }
}
