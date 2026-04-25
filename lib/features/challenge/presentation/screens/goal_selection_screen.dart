import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../cubit/challenge_cubit.dart';
import '../../../../components/app_background_widget.dart';
import '../../../../core/widgets/custom_back_button.dart';

class GoalSelectionScreen extends StatelessWidget {
  const GoalSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 70.w,
        leading: const CustomBackButton(),
        centerTitle: true,
        title: Text(
          'Choose Your Goal',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18.sp,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: Stack(
        children: [
          appBackgroundWidget(),
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 8.h),
                  Padding(
                    padding: EdgeInsets.fromLTRB(5.w, 5.h, 5.w, 10.h),
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
                          'PICK YOUR COMMITMENT',
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
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 5.w),
                    child: Text(
                      'Select how many days you want to commit to building this habit.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14.sp,
                        height: 1.5,
                      ),
                    ),
                  ),
                  SizedBox(height: 28.h),

                  _ChallengeCard(
                    days: 7,
                    points: 70,
                    icon: '🌱',
                    title: 'Beginner',
                    subtitle: 'Perfect for starting your journey',
                    accent: AppColors.successGreen,
                    onTap: () => _startChallenge(context, 7, 70),
                  ),
                  SizedBox(height: 16.h),

                  _ChallengeCard(
                    days: 14,
                    points: 150,
                    icon: '🔥',
                    title: 'Intermediate',
                    subtitle: 'Build strong habits',
                    accent: AppColors.goldAccent,
                    onTap: () => _startChallenge(context, 14, 150),
                  ),
                  SizedBox(height: 16.h),

                  _ChallengeCard(
                    days: 21,
                    points: 250,
                    icon: '💎',
                    title: 'Advanced',
                    subtitle: 'Master your discipline',
                    accent: AppColors.primaryGreen,
                    onTap: () => _startChallenge(context, 21, 250),
                  ),

                  SizedBox(height: 28.h),

                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(28.r),
                      border: Border.all(
                        color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: EdgeInsets.all(8.w),
                          decoration: BoxDecoration(
                            color: AppColors.goldAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                          child: Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.goldAccent,
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            'Complete daily tasks to earn points. Miss a day and the challenge resets!',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13.sp,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24.h),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startChallenge(BuildContext context, int days, int points) {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<ChallengeCubit>().startChallenge(
        userId: authState.user.id,
        durationDays: days,
        rewardPoints: points,
        challengeType: 'beat_satan',
      );

      context.push('${RouteNames.habitBuilding}?type=beat_satan');
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in first')));
    }
  }
}

class _ChallengeCard extends StatelessWidget {
  final int days;
  final int points;
  final String icon;
  final String title;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _ChallengeCard({
    required this.days,
    required this.points,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(28.r),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(28.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60.w,
                height: 60.w,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: accent.withValues(alpha: 0.25),
                  ),
                ),
                child: Center(
                  child: Text(icon, style: TextStyle(fontSize: 28.sp)),
                ),
              ),
              SizedBox(width: 16.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '$days Days',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8.r),
                            border: Border.all(
                              color: accent.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Text(
                            title,
                            style: TextStyle(
                              color: accent,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12.sp,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              Column(
                children: [
                  Icon(Icons.star_rounded, color: AppColors.goldAccent, size: 22.sp),
                  SizedBox(height: 2.h),
                  Text(
                    '$points',
                    style: TextStyle(
                      color: AppColors.goldAccent,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    'points',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
