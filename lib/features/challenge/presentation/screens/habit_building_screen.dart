import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/challenge_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../widgets/challenge_progress_widget.dart';
import '../../../../components/app_background_widget.dart';

class HabitBuildingScreen extends StatelessWidget {
  const HabitBuildingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white, size: 20.sp),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: BlocBuilder<ChallengeCubit, ChallengeState>(
          builder: (context, state) {
            String title = 'Beat Satan Challenge';
            if (state is ChallengeLoaded &&
                state.challenge != null &&
                state.challenge!.challengeType != null) {
              final t = state.challenge!.challengeType!;
              if (t.startsWith('addiction_')) {
                final parts = t.split('_');
                if (parts.length >= 3) {
                  final id = parts[1];
                  final days = parts[2];
                  final label = _addictionLabel(id);
                  title = '$days-day: $label';
                }
              }
            }
            return Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18.sp,
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          appBackgroundWidget(),
          BlocConsumer<ChallengeCubit, ChallengeState>(
            listener: (context, state) {
              if (state is ChallengeDayCompleted) {
                _showDayCompletedDialog(context, state.pointsEarned);
                Future.delayed(const Duration(seconds: 2), () {
                  if (context.mounted) {
                    context.read<ChallengeCubit>().resetToLoaded();
                  }
                });
              } else if (state is ChallengeFullyCompleted) {
                _showChallengeCompletedDialog(context, state.totalPointsEarned);
              } else if (state is ChallengeError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is ChallengeLoading) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primaryGreen,
                  ),
                );
              }

              if (state is ChallengeLoaded && state.challenge == null) {
                return _buildNoChallengeView(context);
              }

              final challenge = state is ChallengeLoaded
                  ? state.challenge
                  : state is ChallengeDayCompleted
                  ? state.challenge
                  : null;

              if (challenge == null) {
                return _buildNoChallengeView(context);
              }

              return SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 10.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ChallengeProgressWidget(challenge: challenge),
                      SizedBox(height: 24.h),
                      _buildDailyTaskCard(context, challenge),
                      SizedBox(height: 24.h),
                      _buildMotivationSection(context, challenge),
                      SizedBox(height: 32.h),
                      if (challenge.canCompleteToday() &&
                          !challenge.isCompleted)
                        _buildCompleteButton(context),
                      SizedBox(height: 40.h),
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

  Widget _buildNoChallengeView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Icon(
              Icons.description_outlined,
              color: AppColors.goldAccent,
              size: 60.sp,
            ),
          ),
          SizedBox(height: 32.h),
          Text(
            'No Active Challenge',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Start a challenge to begin your journey\nof transformation and discipline.',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14.sp,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDailyTaskCard(BuildContext context, dynamic challenge) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.task_alt,
                  color: AppColors.goldAccent,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Text(
                'Today\'s Focus',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 18.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Text(
            _dailyTaskText(challenge),
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.sp,
              height: 1.6,
            ),
          ),
          SizedBox(height: 20.h),
          Divider(color: Colors.white.withValues(alpha: 0.1)),
          SizedBox(height: 16.h),
          _buildTaskItem('Focus on positive actions'),
          SizedBox(height: 10.h),
          _buildTaskItem('Stay consistent and patient'),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String text) {
    return Row(
      children: [
        Icon(
          Icons.check_circle_outline,
          color: AppColors.successGreen,
          size: 16.sp,
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: Colors.white60, fontSize: 13.sp),
          ),
        ),
      ],
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

  String _dailyTaskText(dynamic challenge) {
    final t = challenge.challengeType;
    if (t != null && t.startsWith('addiction_')) {
      final parts = t.split('_');
      if (parts.length >= 3) {
        final id = parts[1];
        switch (id) {
          case 'porn':
            return '• Avoid triggers and block harmful sources\n• Replace usage with prayer or dhikr\n• Use accountability tools to stay safe';
          case 'smoking':
            return '• Delay the first habit of the day\n• Use physical replacements like gum\n• Connect with a support buddy';
          case 'alcohol':
            return '• Avoid environments with social triggers\n• Stay hydrated and physically active\n• Maintain strict accountability';
          case 'gambling':
            return '• Self-exclude from digital platforms\n• Engage in a constructive new hobby\n• Monitor your urges with mindfulness';
          default:
            return '• Avoid negative habitual repetitions\n• Perform a small good deed instead\n• Maintain high mental consistency';
        }
      }
    }
    return '• Consciously avoid old patterns\n• Replace negative thoughts with dhikr\n• Focus on building a better self today';
  }

  Widget _buildMotivationSection(BuildContext context, dynamic challenge) {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: AppColors.primaryGreen.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(
          color: AppColors.primaryGreen.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: AppColors.goldAccent,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                'Neki Motivation',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            '"Indeed, Allah is with the patient." - Quran 2:153',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontStyle: FontStyle.italic,
              fontSize: 14.sp,
              height: 1.4,
            ),
          ),
          if (challenge.completedDays > 0) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('🔥', style: TextStyle(fontSize: 14.sp)),
                  SizedBox(width: 8.w),
                  Text(
                    '${challenge.completedDays} days completed! Keep it up.',
                    style: TextStyle(
                      color: AppColors.goldAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 13.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompleteButton(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldAccent.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          final authState = context.read<AuthCubit>().state;
          if (authState is Authenticated) {
            context.read<ChallengeCubit>().completeTodayChallenge(
              userId: authState.user.id,
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldAccent,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(vertical: 20.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          elevation: 0,
        ),
        child: Text(
          'Mark Today as Complete ✓',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  void _showDayCompletedDialog(BuildContext context, int points) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Container(
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.all(24.w),
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E21).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(32.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: AppColors.successGreen,
                    size: 48.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Alhamdulillah!',
                  style: TextStyle(
                    color: AppColors.goldAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 24.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'One more step closer. You\'ve earned $points points for your discipline today.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.sp,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: const Text(
                    'Continue Journey',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showChallengeCompletedDialog(BuildContext context, int totalPoints) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Container(
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.all(24.w),
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E21).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(32.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: AppColors.goldAccent,
                    size: 60.sp,
                  ),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Mabrouk!',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 28.sp,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Challenge Completed Successfully',
                  style: TextStyle(
                    color: AppColors.goldAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.h),
                Text(
                  'Total Points Earned: $totalPoints',
                  style: TextStyle(color: Colors.white70, fontSize: 16.sp),
                ),
                SizedBox(height: 32.h),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: const Text(
                    'Return Home',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
