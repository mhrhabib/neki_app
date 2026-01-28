import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/routes/route_names.dart';
import '../cubit/onboarding_cubit.dart';

class GoalSelectionScreen extends StatefulWidget {
  const GoalSelectionScreen({super.key});

  @override
  State<GoalSelectionScreen> createState() => _GoalSelectionScreenState();
}

class _GoalSelectionScreenState extends State<GoalSelectionScreen> {
  int _selectedOptionIndex = 0; // Default to first option (7 days)

  final List<Map<String, dynamic>> _goals = [
    {
      'days': 7,
      'points': 100,
      'title': '7 Days Starter',
      'description': 'Build the habit. Defeat the whispers.',
      'icon': '🛡️',
    },
    {
      'days': 14,
      'points': 200,
      'title': '14 Days Warrior',
      'description': 'Strengthen your resolve. Gain momentum.',
      'icon': '⚔️',
    },
    {
      'days': 21,
      'points': 300,
      'title': '21 Days Champion',
      'description': 'Form a lasting habit. Break the chains.',
      'icon': '👑',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // If not using dark mode logic yet in the rest of the app for this screen,
    // defaults to the soft cream / light theme as per OnboardingScreen reference.
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF0A0E27) : AppColors.softCream;
    final textColor = isDark ? Colors.white : AppColors.textDark;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
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
                'Beat Satan\nChallenge',
                style: AppTypography.h1.copyWith(color: AppColors.primaryGreen, fontSize: 32.sp, height: 1.2),
              ),
              SizedBox(height: AppSpacing.gridGap),
              Text(
                'Prophet Muhammad (ﷺ) said: "The most beloved of deeds to Allah are those that are most consistent, even if they are small."',
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textGray,
                  fontStyle: FontStyle.italic,
                  fontSize: 14.sp,
                ),
              ),
              SizedBox(height: AppSpacing.sectionSpacing),
              Expanded(
                child: ListView.separated(
                  itemCount: _goals.length,
                  separatorBuilder: (context, index) => SizedBox(height: AppSpacing.gridGap),
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    final isSelected = _selectedOptionIndex == index;

                    return GestureDetector(
                      onTap: () => setState(() => _selectedOptionIndex = index),
                      child: Container(
                        padding: EdgeInsets.all(16.w),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isSelected ? AppColors.primaryGreen : Colors.transparent,
                            width: 2.w,
                          ),
                          boxShadow: [
                            if (isSelected)
                              BoxShadow(
                                color: AppColors.primaryGreen.withValues(alpha: 0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 50.w,
                              height: 50.w,
                              decoration: BoxDecoration(
                                color: AppColors.softCream,
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              alignment: Alignment.center,
                              child: Text(goal['icon'], style: TextStyle(fontSize: 24.sp)),
                            ),
                            SizedBox(width: 16.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    goal['title'],
                                    style: AppTypography.h2.copyWith(color: textColor, fontSize: 18.sp),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    goal['description'],
                                    style: AppTypography.caption.copyWith(
                                      color: isDark ? Colors.white60 : AppColors.textGray,
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                    decoration: BoxDecoration(
                                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      'Target: ${goal['points']} Neki Points',
                                      style: TextStyle(
                                        fontSize: 12.sp,
                                        color: AppColors.primaryGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected) Icon(Icons.check_circle, color: AppColors.primaryGreen, size: 24.sp),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: AppSpacing.sectionSpacing),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final selectedGoal = _goals[_selectedOptionIndex];
                    final cubit = context.read<OnboardingCubit>();

                    // Save goal, don't complete yet
                    cubit.saveGoal(selectedGoal['days'], selectedGoal['points']);

                    // Navigate to habit building explanation using go_router
                    context.go(RouteNames.habitBuildingOnboarding);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: EdgeInsets.all(16.w),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.cornerRadius)),
                    elevation: 4,
                  ),
                  child: Text(
                    'I Accept the Challenge',
                    style: AppTypography.button.copyWith(color: Colors.white, fontSize: 16.sp),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
