import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routes/route_names.dart';
import '../cubit/onboarding_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../challenge/presentation/cubit/challenge_cubit.dart';
import '../../../../components/app_background_widget.dart';

class HabitBuildingScreen extends StatelessWidget {
  const HabitBuildingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        appBackgroundWidget(),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.outerPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'The Path to\nSuccess',
                    style: GoogleFonts.sanchez(
                      color: AppColors.goldAccent,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionSpacing),
                  _buildMethodologyItem(
                    context,
                    icon: '🕌',
                    title: 'Establish Salah',
                    description:
                        'The foundation of your connection with Allah. Make it your priority.',
                  ),
                  SizedBox(height: AppSpacing.gridGap * 2),
                  _buildMethodologyItem(
                    context,
                    icon: '🛡️',
                    title: 'Avoid Sins',
                    description:
                        'Build the shield of Taqwa against Shaytan\'s whispers.',
                  ),
                  SizedBox(height: AppSpacing.gridGap * 2),
                  _buildMethodologyItem(
                    context,
                    icon: '💧',
                    title: 'Consistency',
                    description:
                        '"The most beloved of deeds to Allah are those that are most consistent."',
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final onboardingCubit = context.read<OnboardingCubit>();
                        final authState = context.read<AuthCubit>().state;

                        // Mark onboarding as complete
                        onboardingCubit.completeOnboarding();

                        if (authState is Authenticated) {
                          // User is already logged in — create the challenge
                          // and go to home
                          final goal = await onboardingCubit
                              .onboardingRepository
                              .getChallengeGoal();
                          if (goal != null && context.mounted) {
                            context.read<ChallengeCubit>().startChallenge(
                              userId: authState.user.id,
                              durationDays: goal['days'] as int,
                              rewardPoints: goal['points'] as int,
                              challengeType: 'beat_satan',
                            );
                          }
                          if (context.mounted) {
                            context.go(RouteNames.home);
                          }
                        } else {
                          // First-time onboarding — send to login
                          if (context.mounted) {
                            context.go(RouteNames.login);
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldAccent,
                        foregroundColor: Colors.black,
                        padding: EdgeInsets.all(16.w),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppSpacing.cornerRadius,
                          ),
                        ),
                        elevation: 4,
                      ),
                      child: Text(
                        'Bismillah / Start Journey',
                        style: GoogleFonts.sanchez(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.gridGap),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMethodologyItem(
    BuildContext context, {
    required String icon,
    required String title,
    required String description,
  }) {
    return Row(
      children: [
        Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            color: AppColors.goldAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.3),
            ),
          ),
          alignment: Alignment.center,
          child: Text(icon, style: TextStyle(fontSize: 24.sp)),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.sanchez(
                  color: AppColors.goldAccent,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: GoogleFonts.sanchez(
                  color: Colors.white70,
                  fontSize: 14.sp,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
