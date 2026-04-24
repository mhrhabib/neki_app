import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:neki_app/core/routes/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../components/app_background_widget.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../challenge/domain/entities/challenge_entity.dart';
import '../../../challenge/presentation/cubit/challenge_cubit.dart';

class AddictionScreen extends StatelessWidget {
  const AddictionScreen({super.key});

  static const List<_AddictionItem> _items = [
    _AddictionItem(
      id: 'porn',
      title: 'Porn Addiction',
      desc: 'Reduce exposure, set blockers, replace with healthy habits.',
      icon: CupertinoIcons.eye_slash_fill,
    ),
    _AddictionItem(
      id: 'smoking',
      title: 'Smoking',
      desc: 'Delay the first cigarette, find replacements, seek support.',
      icon: Icons.smoke_free_rounded,
    ),
    _AddictionItem(
      id: 'alcohol',
      title: 'Alcohol',
      desc: 'Avoid triggers, build sober routines, seek accountability.',
      icon: CupertinoIcons.drop_fill,
    ),
    _AddictionItem(
      id: 'gambling',
      title: 'Gambling',
      desc: 'Self-exclude, block sites, find alternative activities.',
      icon: CupertinoIcons.money_dollar_circle_fill,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          appBackgroundWidget(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 12.h,
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            CupertinoIcons.chevron_left,
                            size: 20.sp,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            "Recovery Center",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 40.w), // Balance for back button
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(25.w, 15.h, 25.w, 10.h),
                  child: Row(
                    children: [
                      Container(
                        width: 4.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: AppColors.goldAccent,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        'PICK SOMETHING TO QUIT',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w900,
                          color: AppColors.goldAccent,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: BlocBuilder<ChallengeCubit, ChallengeState>(
                    builder: (context, challengeState) {
                      Map<String, ChallengeEntity> active = const {};
                      if (challengeState is ChallengeLoaded) {
                        active = challengeState.challenges;
                      }
                      return ListView.separated(
                        padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
                        itemCount: _items.length,
                        separatorBuilder: (context, index) =>
                            SizedBox(height: 16.h),
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final activeChallenge = active['addiction_${item.id}'];
                          return _buildCard(context, item, isDark, activeChallenge);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    _AddictionItem item,
    bool isDark,
    ChallengeEntity? active,
  ) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  item.icon,
                  color: AppColors.goldAccent,
                  size: 22.sp,
                ),
              ),
              SizedBox(width: 15.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      active != null && active.isActive
                          ? 'Tracking · ${active.daysClean} day${active.daysClean == 1 ? '' : 's'} clean'
                          : 'Recovery Program',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppColors.goldAccent.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _showTips(context, item),
                icon: Icon(
                  CupertinoIcons.info_circle,
                  color: Colors.white38,
                  size: 20.sp,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          SizedBox(height: 15.h),
          Text(
            item.desc,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white60,
              height: 1.4,
            ),
          ),
          SizedBox(height: 20.h),
          if (active != null && active.isActive)
            _buildOpenButton(context, item)
          else
            _buildStartButton(context, item),
        ],
      ),
    );
  }

  Widget _buildOpenButton(BuildContext context, _AddictionItem item) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => context.push(
          '${RouteNames.addictionTracker}?type=addiction_${item.id}',
        ),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 14.h),
          side: BorderSide(
            color: AppColors.goldAccent.withValues(alpha: 0.4),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
          ),
        ),
        icon: Icon(Icons.bar_chart_rounded, color: AppColors.goldAccent, size: 20.sp),
        label: Text(
          'OPEN TRACKER',
          style: TextStyle(
            color: AppColors.goldAccent,
            fontSize: 14.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, _AddictionItem item) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14.r),
          gradient: LinearGradient(
            colors: [AppColors.primaryGreen, const Color(0xFF1E4D35)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: () => _confirmStart(context, item),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          icon: Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22.sp),
          label: Text(
            'START TRACKING',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    );
  }

  void _showTips(BuildContext context, _AddictionItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: AppColors.goldAccent.withValues(alpha: 0.2)),
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: AppColors.goldAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.desc,
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            ),
            SizedBox(height: 15.h),
            _buildTipItem(context, 'Set clear and achievable goals'),
            _buildTipItem(
              context,
              'Replace the habit with positive activities',
            ),
            _buildTipItem(
              context,
              'Seek professional support or accountability',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Got it',
              style: TextStyle(color: AppColors.goldAccent),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.primaryGreen,
            size: 16.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.white60, fontSize: 13.sp),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmStart(BuildContext context, _AddictionItem item) {
    // Capture the picker-screen context BEFORE the dialog runs. Inside the
    // dialog builder, `context` is the dialog's own context — using it for
    // navigation after `Navigator.pop` would call into a disposed element
    // and crash.
    final pickerContext = context;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: AppColors.goldAccent.withValues(alpha: 0.2)),
        ),
        title: Text(
          'Begin Your Journey',
          style: TextStyle(
            color: AppColors.goldAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Your ${item.title} sobriety counter will start now and run continuously. You\'ll earn Neki points at each milestone (1 day, 7 days, 30 days, and beyond). Only an "I relapsed" tap resets the streak.',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white24),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final authState = pickerContext.read<AuthCubit>().state;
              if (authState is! Authenticated) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(pickerContext).showSnackBar(
                  const SnackBar(content: Text('Please log in first')),
                );
                return;
              }

              try {
                // Await the start so the Firestore doc exists before navigating.
                await pickerContext.read<ChallengeCubit>().startChallenge(
                      userId: authState.user.id,
                      durationDays: 0, // 0 = unbounded duration for addiction tracking
                      rewardPoints: 0,
                      challengeType: 'addiction_${item.id}',
                    );
              } catch (e) {
                Navigator.pop(dialogContext);
                ScaffoldMessenger.of(pickerContext).showSnackBar(
                  SnackBar(content: Text('Failed to start tracker: $e')),
                );
                return;
              }

              // Pop FIRST, then navigate using the picker's still-valid
              // context — never the dialog's context after dismissal.
              Navigator.pop(dialogContext);
              pickerContext.push(
                '${RouteNames.addictionTracker}?type=addiction_${item.id}',
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: const Text(
              'Start Tracking',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddictionItem {
  final String id;
  final String title;
  final String desc;
  final IconData icon;

  const _AddictionItem({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
  });
}
