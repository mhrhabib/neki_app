import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
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
      backgroundColor: isDark ? const Color(0xFF0A0E27) : AppColors.softCream,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Recovery Plans',
          style: AppTypography.h2.copyWith(color: isDark ? Colors.white : AppColors.textDark),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Choose an area to work on', style: AppTypography.h2.copyWith(fontSize: 18.sp)),
              SizedBox(height: 12.h),
              Expanded(
                child: ListView.separated(
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => SizedBox(height: 12.h),
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return _buildCard(context, item, isDark);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard(BuildContext context, _AddictionItem item, bool isDark) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.title, style: AppTypography.h2.copyWith(fontSize: 16.sp)),
              ),
              IconButton(
                onPressed: () => _showTips(context, item),
                icon: Icon(Icons.info_outline, color: isDark ? Colors.white70 : AppColors.primaryGreen),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(item.desc, style: AppTypography.body.copyWith(color: isDark ? Colors.white70 : AppColors.textGray)),
          SizedBox(height: 12.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: [
              ElevatedButton(
                onPressed: () => _confirmStart(context, item, 7, item.points7),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                child: const Text('Start 7-day'),
              ),
              ElevatedButton(
                onPressed: () => _confirmStart(context, item, 14, item.points14),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                child: const Text('Start 14-day'),
              ),
              ElevatedButton(
                onPressed: () => _confirmStart(context, item, 21, item.points21),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                child: const Text('Start 21-day'),
              ),
              TextButton(
                onPressed: () => _openSupportResources(context, item),
                child: const Text('Support & Resources'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showTips(BuildContext context, _AddictionItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(item.title),
        content: Text(
          'Tips to overcome ${item.title.toLowerCase()}:\n\n${item.desc}\n\n• Set clear goals\n• Replace the habit with positive activities\n• Seek accountability and support\n• Use app tools to track daily progress',
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  void _openSupportResources(BuildContext context, _AddictionItem item) {
    // For now show a simple dialog. Could be extended to open web resources or local help content.
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support & Resources'),
        content: const Text(
          'You can join local support groups, seek counseling, or use digital blockers and accountability apps.',
        ),
        actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Close'))],
      ),
    );
  }

  void _confirmStart(BuildContext context, _AddictionItem item, int days, int points) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start ${days}-day plan?'),
        content: Text(
          'Start a ${days}-day recovery plan for ${item.title} and earn $points points on completion. Are you sure you want to proceed?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              // Start challenge and navigate
              context.read<ChallengeCubit>().startChallenge(
                durationDays: days,
                rewardPoints: points,
                challengeType: 'addiction_${item.id}_$days',
              );

              Navigator.of(context).pop();
              context.push('/habit-building');
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
