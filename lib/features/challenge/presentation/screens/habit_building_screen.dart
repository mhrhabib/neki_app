import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../cubit/challenge_cubit.dart';
import '../widgets/challenge_progress_widget.dart';

class HabitBuildingScreen extends StatelessWidget {
  const HabitBuildingScreen({super.key});

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
        title: BlocBuilder<ChallengeCubit, ChallengeState>(
          builder: (context, state) {
            String title = 'Beat Satan Challenge';
            if (state is ChallengeLoaded && state.challenge != null && state.challenge!.challengeType != null) {
              final t = state.challenge!.challengeType!;
              if (t.startsWith('addiction_')) {
                // format: addiction_<id>_<days>
                final parts = t.split('_');
                if (parts.length >= 3) {
                  final id = parts[1];
                  final days = parts[2];
                  final label = _addictionLabel(id);
                  title = '${days}-day: $label';
                }
              }
            }
            return Text(title, style: AppTypography.h2.copyWith(color: isDark ? Colors.white : AppColors.textDark));
          },
        ),
      ),
      body: BlocConsumer<ChallengeCubit, ChallengeState>(
        listener: (context, state) {
          if (state is ChallengeDayCompleted) {
            _showDayCompletedDialog(context, state.pointsEarned);
            // Reset to loaded state after showing dialog
            Future.delayed(const Duration(seconds: 2), () {
              if (context.mounted) {
                context.read<ChallengeCubit>().resetToLoaded();
              }
            });
          } else if (state is ChallengeFullyCompleted) {
            _showChallengeCompletedDialog(context, state.totalPointsEarned);
          } else if (state is ChallengeError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
          }
        },
        builder: (context, state) {
          if (state is ChallengeLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ChallengeLoaded && state.challenge == null) {
            return _buildNoChallengeView(context, isDark);
          }

          final challenge = state is ChallengeLoaded
              ? state.challenge
              : state is ChallengeDayCompleted
              ? state.challenge
              : null;

          if (challenge == null) {
            return _buildNoChallengeView(context, isDark);
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(AppSpacing.outerPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Challenge progress card
                ChallengeProgressWidget(challenge: challenge),

                SizedBox(height: 24.h),

                // Daily task card
                _buildDailyTaskCard(context, challenge, isDark),

                SizedBox(height: 24.h),

                // Motivation section
                _buildMotivationSection(context, challenge, isDark),

                SizedBox(height: 24.h),

                // Complete today button
                if (challenge.canCompleteToday() && !challenge.isCompleted) _buildCompleteButton(context, isDark),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNoChallengeView(BuildContext context, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('📝', style: TextStyle(fontSize: 80.sp)),
          SizedBox(height: 24.h),
          Text(
            'No Active Challenge',
            style: AppTypography.h2.copyWith(color: isDark ? Colors.white : AppColors.textDark),
          ),
          SizedBox(height: 12.h),
          Text(
            'Start a challenge to track your progress',
            style: AppTypography.body.copyWith(color: isDark ? Colors.white70 : AppColors.textGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTaskCard(BuildContext context, challenge, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isDark ? const Color(0xFF374151) : AppColors.dividerGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.task_alt, color: AppColors.primaryGreen, size: 24.sp),
              SizedBox(width: 12.w),
              Text(
                'Today\'s Task',
                style: AppTypography.h2.copyWith(color: isDark ? Colors.white : AppColors.textDark),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            _dailyTaskText(challenge),
            style: AppTypography.body.copyWith(color: isDark ? Colors.white : AppColors.textDark),
          ),
          SizedBox(height: 8.h),
          SizedBox(height: 8.h),
          Text(
            '✅ Focus on positive actions',
            style: AppTypography.body.copyWith(color: isDark ? Colors.white : AppColors.textDark),
          ),
          SizedBox(height: 8.h),
          Text(
            '✅ Stay consistent and patient',
            style: AppTypography.body.copyWith(color: isDark ? Colors.white : AppColors.textDark),
          ),
        ],
      ),
    );
  }

  String _addictionLabel(String id) {
    switch (id) {
      case 'porn':
        return 'Porn Recovery';
      case 'smoking':
        return 'Smoking Recovery';
      case 'alcohol':
        return 'Alcohol Recovery';
      case 'gambling':
        return 'Gambling Recovery';
      default:
        return 'Habit Challenge';
    }
  }

  String _dailyTaskText(challenge) {
    final t = challenge.challengeType;
    if (t != null && t.startsWith('addiction_')) {
      final parts = t.split('_');
      if (parts.length >= 3) {
        final id = parts[1];
        switch (id) {
          case 'porn':
            return '✅ Avoid triggers and block sources\n✅ Replace usage with prayer/dhikr\n✅ Use accountability tools';
          case 'smoking':
            return '✅ Delay first cigarette\n✅ Chew gum or use replacements\n✅ Reach out to a buddy for support';
          case 'alcohol':
            return '✅ Avoid social triggers\n✅ Drink water and go for a walk\n✅ Seek accountability';
          case 'gambling':
            return '✅ Self-exclude from sites\n✅ Replace with a hobby\n✅ Seek help if urges persist';
          default:
            return '✅ Avoid bad habits\n✅ Do a good deed instead\n✅ Keep consistent';
        }
      }
    }
    return '✅ Avoid sin and bad habits\n✅ Focus on positive actions\n✅ Stay consistent and patient';
  }

  Widget _buildMotivationSection(BuildContext context, challenge, bool isDark) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryGreen.withOpacity(0.2), AppColors.primaryGreen.withOpacity(0.1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.primaryGreen.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '💪 Keep Going!',
            style: AppTypography.h2.copyWith(
              color: isDark ? Colors.white : AppColors.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            '"Indeed, Allah is with the patient." - Quran 2:153',
            style: AppTypography.body.copyWith(
              color: isDark ? Colors.white70 : AppColors.textGray,
              fontStyle: FontStyle.italic,
            ),
          ),
          SizedBox(height: 12.h),
          if (challenge.completedDays > 0)
            Text(
              '🔥 You\'ve completed ${challenge.completedDays} ${challenge.completedDays == 1 ? 'day' : 'days'}! Keep up the amazing work!',
              style: AppTypography.body.copyWith(
                color: isDark ? Colors.white : AppColors.primaryGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCompleteButton(BuildContext context, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          context.read<ChallengeCubit>().completeTodayChallenge();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
        ),
        child: Text(
          'Mark Today as Complete ✓',
          style: AppTypography.button.copyWith(color: Colors.white, fontSize: 16.sp),
        ),
      ),
    );
  }

  void _showDayCompletedDialog(BuildContext context, int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✅', style: TextStyle(fontSize: 60.sp)),
            SizedBox(height: 16.h),
            Text(
              'Alhamdulillah!',
              style: AppTypography.h2.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            Text('You earned $points points!', style: AppTypography.body, textAlign: TextAlign.center),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }

  void _showChallengeCompletedDialog(BuildContext context, int totalPoints) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎉', style: TextStyle(fontSize: 80.sp)),
            SizedBox(height: 16.h),
            Text(
              'Alhamdulillah!',
              style: AppTypography.h1.copyWith(color: AppColors.primaryGreen, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12.h),
            Text('Challenge Completed!', style: AppTypography.h2, textAlign: TextAlign.center),
            SizedBox(height: 12.h),
            Text(
              'Total Points Earned: $totalPoints',
              style: AppTypography.body.copyWith(
                color: AppColors.goldAccent,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.pop(); // Go back to home
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryGreen),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
