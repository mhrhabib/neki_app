import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:url_launcher/url_launcher.dart';
import '../cubit/salah_lock_cubit.dart';

class SalahLockSettingsScreen extends StatelessWidget {
  const SalahLockSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2818),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Salah Lock Mode',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new), onPressed: () => Navigator.pop(context)),
      ),
      body: BlocBuilder<SalahLockCubit, SalahLockState>(
        builder: (context, state) {
          if (state is SalahLockLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final cubit = context.read<SalahLockCubit>();
          final settings = state.settings;

          return ListView(
            padding: EdgeInsets.all(20.w),
            children: [
              _buildSectionHeader('CORE SETTINGS'),
              _buildToggleTile(
                title: 'Enable Salah Lock Mode',
                subtitle: 'Globally lock the app during prayer times',
                value: settings.isEnabled,
                onChanged: (val) => cubit.updateSettings(settings.copyWith(isEnabled: val)),
              ),
              SizedBox(height: 24.h),
              _buildSectionHeader('PLATFORM SPECIFIC'),
              _buildToggleTile(
                title: 'Lock Device Screen (Android)',
                subtitle: 'Physically lock the device via Device Admin',
                value: settings.lockDeviceAndroid,
                onChanged: (val) async {
                  if (val) {
                    final isActive = await cubit.deviceManager.isDeviceAdminActive();
                    if (!isActive) {
                      await cubit.deviceManager.requestDeviceAdmin();
                      return;
                    }
                  }
                  cubit.updateSettings(settings.copyWith(lockDeviceAndroid: val));
                },
              ),
              _buildToggleTile(
                title: 'Block Distracting Apps (Android)',
                subtitle: 'Blocks social media & games during prayer',
                value: settings.blockedApps.isNotEmpty,
                onChanged: (val) async {
                  if (val) {
                    final granted = await cubit.checkAndRequestAndroidPermissions();
                    if (!granted) return;

                    // Example blocked apps (Production apps should allow choosing)
                    final apps = [
                      'com.facebook.katana',
                      'com.instagram.android',
                      'com.zhiliaoapp.musically', // TikTok
                      'com.twitter.android',
                      'com.whatsapp',
                    ];
                    cubit.updateSettings(settings.copyWith(blockedApps: apps));
                  } else {
                    cubit.updateSettings(settings.copyWith(blockedApps: []));
                  }
                },
              ),
              _buildToggleTile(
                title: 'Auto-Lock Social Media (iOS)',
                subtitle: 'Configure app limits in Screen Time settings',
                value: settings.autoLockSocialIos,
                onChanged: (val) async {
                  if (val) {
                    await cubit.deviceManager.requestIOSAuthorization();
                    final urls = [Uri.parse('App-Prefs:root=SCREEN_TIME'), Uri.parse('prefs:root=SCREEN_TIME')];
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
              _buildSectionHeader('ADVANCED'),
              _buildToggleTile(
                title: 'Enable Streak Tracking',
                subtitle: 'Keep track of your prayer consistency',
                value: settings.streakTracking,
                onChanged: (val) => cubit.updateSettings(settings.copyWith(streakTracking: val)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Auto-Unlock Buffer',
                  style: TextStyle(color: Colors.white, fontSize: 15.sp),
                ),
                subtitle: Text(
                  'Automatically unlock after ${settings.autoUnlockMinutes} minutes',
                  style: TextStyle(color: Colors.white60, fontSize: 13.sp),
                ),
                trailing: Text(
                  'Edit',
                  style: TextStyle(color: const Color(0xFF4ADE80), fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  // Show numeric picker or dialog
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h, top: 8.h),
      child: Text(
        title,
        style: TextStyle(
          color: const Color(0xFF4ADE80),
          fontSize: 12.sp,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildToggleTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16.r)),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white60, fontSize: 12.sp),
        ),
        trailing: CupertinoSwitch(
          activeTrackColor: const Color(0xFF4ADE80),
          inactiveTrackColor: Colors.white10,
          value: value,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
