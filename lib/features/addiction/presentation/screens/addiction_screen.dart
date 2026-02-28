import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../components/app_background_widget.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../challenge/presentation/cubit/challenge_cubit.dart';

class AddictionScreen extends StatelessWidget {
  const AddictionScreen({super.key});

  static const List<_AddictionItem> _items = [
    _AddictionItem(
      id: 'porn',
      title: 'Porn Addiction',
      desc: 'Reduce exposure, set blockers, replace with healthy habits.',
      icon: CupertinoIcons.eye_slash_fill,
      points7: 80,
      points14: 170,
      points21: 300,
    ),
    _AddictionItem(
      id: 'smoking',
      title: 'Smoking',
      desc: 'Delay the first cigarette, find replacements, seek support.',
      icon: Icons.smoke_free_rounded,
      points7: 70,
      points14: 150,
      points21: 250,
    ),
    _AddictionItem(
      id: 'alcohol',
      title: 'Alcohol',
      desc: 'Avoid triggers, build sober routines, seek accountability.',
      icon: CupertinoIcons.drop_fill,
      points7: 90,
      points14: 180,
      points21: 320,
    ),
    _AddictionItem(
      id: 'gambling',
      title: 'Gambling',
      desc: 'Self-exclude, block sites, find alternative activities.',
      icon: CupertinoIcons.money_dollar_circle_fill,
      points7: 60,
      points14: 130,
      points21: 220,
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
                        'CHOOSE A RECOVERY PLAN',
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
                  child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 30.h),
                    itemCount: _items.length,
                    separatorBuilder: (context, index) =>
                        SizedBox(height: 16.h),
                    itemBuilder: (context, index) {
                      final item = _items[index];
                      return _buildCard(context, item, isDark);
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

  Widget _buildCard(BuildContext context, _AddictionItem item, bool isDark) {
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
                      'Recovery Program',
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
          Row(
            children: [
              _buildPlanButton(context, item, 7, item.points7),
              SizedBox(width: 10.w),
              _buildPlanButton(context, item, 14, item.points14),
              SizedBox(width: 10.w),
              _buildPlanButton(context, item, 21, item.points21),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanButton(
    BuildContext context,
    _AddictionItem item,
    int days,
    int points,
  ) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.r),
          gradient: LinearGradient(
            colors: [AppColors.primaryGreen, const Color(0xFF1E4D35)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primaryGreen.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: () => _confirmStart(context, item, days, points),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: 8.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          child: Column(
            children: [
              Text(
                '$days',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                'DAYS',
                style: TextStyle(
                  fontSize: 8.sp,
                  fontWeight: FontWeight.w900,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 0.5,
                ),
              ),
            ],
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

  void _confirmStart(
    BuildContext context,
    _AddictionItem item,
    int days,
    int points,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
          side: BorderSide(color: AppColors.goldAccent.withValues(alpha: 0.2)),
        ),
        title: Text(
          'Confirm Recovery Plan',
          style: TextStyle(
            color: AppColors.goldAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Do you want to start a $days-day recovery plan for ${item.title}? You will earn $points points upon successful completion.',
          style: TextStyle(color: Colors.white70, fontSize: 14.sp),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white24),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final authState = context.read<AuthCubit>().state;
              if (authState is Authenticated) {
                context.read<ChallengeCubit>().startChallenge(
                  userId: authState.user.id,
                  durationDays: days,
                  rewardPoints: points,
                  challengeType: 'addiction_${item.id}_$days',
                );
                Navigator.pop(context);
                context.push('/habit-building');
              } else {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please log in first')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryGreen,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: const Text(
              'Start Plan',
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
  final int points7;
  final int points14;
  final int points21;

  const _AddictionItem({
    required this.id,
    required this.title,
    required this.desc,
    required this.icon,
    required this.points7,
    required this.points14,
    required this.points21,
  });
}
