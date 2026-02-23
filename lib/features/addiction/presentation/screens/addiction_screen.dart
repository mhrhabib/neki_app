import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../challenge/presentation/cubit/challenge_cubit.dart';

class AddictionScreen extends StatelessWidget {
  const AddictionScreen({super.key});

  static const List<_AddictionItem> _items = [
    _AddictionItem(
      id: 'porn',
      title: 'Porn Addiction',
      desc: 'Reduce exposure, set blockers, replace with healthy habits.',
      points7: 80,
      points14: 170,
      points21: 300,
    ),
    _AddictionItem(
      id: 'smoking',
      title: 'Smoking',
      desc: 'Delay the first cigarette, find replacements, seek support.',
      points7: 70,
      points14: 150,
      points21: 250,
    ),
    _AddictionItem(
      id: 'alcohol',
      title: 'Alcohol',
      desc: 'Avoid triggers, build sober routines, seek accountability.',
      points7: 90,
      points14: 180,
      points21: 320,
    ),
    _AddictionItem(
      id: 'gambling',
      title: 'Gambling',
      desc: 'Self-exclude, block sites, find alternative activities.',
      points7: 60,
      points14: 130,
      points21: 220,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Colors.black : AppColors.iosBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Row(
                      children: [
                        Icon(CupertinoIcons.chevron_left, size: 24.sp, color: AppColors.primaryGreen),
                        Text(
                          'Back',
                          style: TextStyle(color: AppColors.primaryGreen, fontSize: 17.sp),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    "Recovery",
                    style: TextStyle(fontSize: 17.sp, fontWeight: FontWeight.w600, letterSpacing: -0.4),
                  ),
                  SizedBox(width: 60.w), // Balance
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'CHOOSE A PLAN',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF8E8E93),
                    letterSpacing: -0.07,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                itemCount: _items.length,
                separatorBuilder: (context, index) => SizedBox(height: 12.h),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  return _buildCard(context, item, isDark);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, _AddictionItem item, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textDark,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showTips(context, item),
                child: Icon(CupertinoIcons.info, color: AppColors.primaryGreen, size: 20.sp),
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            item.desc,
            style: TextStyle(fontSize: 14.sp, color: const Color(0xFF8E8E93)),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              _buildPlanButton(context, item, 7, item.points7),
              SizedBox(width: 8.w),
              _buildPlanButton(context, item, 14, item.points14),
              SizedBox(width: 8.w),
              _buildPlanButton(context, item, 21, item.points21),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlanButton(BuildContext context, _AddictionItem item, int days, int points) {
    return Expanded(
      child: CupertinoButton(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        color: AppColors.primaryGreen,
        borderRadius: BorderRadius.circular(8.r),
        onPressed: () => _confirmStart(context, item, days, points),
        child: Text(
          '$days-day',
          style: TextStyle(fontSize: 12.sp, color: Colors.white),
        ),
      ),
    );
  }

  void _showTips(BuildContext context, _AddictionItem item) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(item.title),
        content: Text(
          'Tips to overcome ${item.title.toLowerCase()}:\n\n${item.desc}\n\n• Set clear goals\n• Replace the habit with positive activities\n• Seek accountability and support',
        ),
        actions: [CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _confirmStart(BuildContext context, _AddictionItem item, int days, int points) {
    showCupertinoDialog(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text('Start $days-day plan?'),
        content: Text('Start a $days-day recovery plan for ${item.title} and earn $points points on completion.'),
        actions: [
          CupertinoDialogAction(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          CupertinoDialogAction(
            isDefaultAction: true,
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
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first')));
              }
            },
            child: const Text('Start'),
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
  final int points7;
  final int points14;
  final int points21;

  const _AddictionItem({
    required this.id,
    required this.title,
    required this.desc,
    required this.points7,
    required this.points14,
    required this.points21,
  });
}
