import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routes/route_names.dart';
import '../cubit/onboarding_cubit.dart';
import '../../../../components/app_background_widget.dart';

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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          appBackgroundWidget(),
          SafeArea(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.outerPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Beat Satan\nChallenge',
                    style: GoogleFonts.sanchez(
                      color: AppColors.goldAccent,
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                      height: 1.2,
                      letterSpacing: 2,
                    ),
                  ),
                  SizedBox(height: AppSpacing.gridGap),
                  Text(
                    'Prophet Muhammad (ﷺ) said: "The most beloved of deeds to Allah are those that are most consistent, even if they are small."',
                    style: GoogleFonts.sanchez(
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                      fontSize: 14.sp,
                    ),
                  ),
                  SizedBox(height: AppSpacing.sectionSpacing),
                  Expanded(
                    child: ListView.separated(
                      itemCount: _goals.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: AppSpacing.gridGap),
                      itemBuilder: (context, index) {
                        final goal = _goals[index];
                        final isSelected = _selectedOptionIndex == index;

                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedOptionIndex = index),
                          child: Container(
                            padding: EdgeInsets.all(16.w),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.goldAccent.withValues(alpha: 0.15)
                                  : Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.goldAccent
                                    : Colors.white.withValues(alpha: 0.1),
                                width: 2.w,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 50.w,
                                  height: 50.w,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    goal['icon'],
                                    style: TextStyle(fontSize: 24.sp),
                                  ),
                                ),
                                SizedBox(width: 16.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        goal['title'],
                                        style: GoogleFonts.sanchez(
                                          color: isSelected
                                              ? AppColors.goldAccent
                                              : Colors.white,
                                          fontSize: 18.sp,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: 4.h),
                                      Text(
                                        goal['description'],
                                        style: GoogleFonts.sanchez(
                                          color: Colors.white60,
                                          fontSize: 12.sp,
                                        ),
                                      ),
                                      SizedBox(height: 8.h),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 8.w,
                                          vertical: 4.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.goldAccent
                                              .withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            8.r,
                                          ),
                                        ),
                                        child: Text(
                                          'Target: ${goal['points']} Neki Points',
                                          style: GoogleFonts.sanchez(
                                            fontSize: 11.sp,
                                            color: AppColors.goldAccent,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: AppColors.goldAccent,
                                    size: 24.sp,
                                  ),
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
                        cubit.saveGoal(
                          selectedGoal['days'],
                          selectedGoal['points'],
                        );

                        // Navigate to habit building explanation using go_router
                        context.push(RouteNames.habitBuildingOnboarding);
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
                        'I Accept the Challenge',
                        style: GoogleFonts.sanchez(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
