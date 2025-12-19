import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/app_typography.dart';
import '../cubit/onboarding_cubit.dart';

class HabitBuildingScreen extends StatelessWidget {
  const HabitBuildingScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
                'The Path to\nSuccess',
                style: AppTypography.h1.copyWith(color: AppColors.primaryGreen, fontSize: 32.sp, height: 1.2),
              ),
              SizedBox(height: AppSpacing.sectionSpacing),
              _buildMethodologyItem(
                context,
                icon: '🕌',
                title: 'Establish Salah',
                description: 'The foundation of your connection with Allah. Make it your priority.',
                isDark: isDark,
              ),
              SizedBox(height: AppSpacing.gridGap * 2),
              _buildMethodologyItem(
                context,
                icon: '🛡️',
                title: 'Avoid Sins',
                description: 'Build the shield of Taqwa against Shaytan\'s whispers.',
                isDark: isDark,
              ),
              SizedBox(height: AppSpacing.gridGap * 2),
              _buildMethodologyItem(
                context,
                icon: '💧',
                title: 'Consistency',
                description: '"The most beloved of deeds to Allah are those that are most consistent."',
                isDark: isDark,
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final cubit = context.read<OnboardingCubit>();
                    cubit.completeOnboarding();
                    context.go('/login');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    padding: EdgeInsets.all(16.w),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.cornerRadius)),
                    elevation: 4,
                  ),
                  child: Text(
                    'Bismillah / Start Journey',
                    style: AppTypography.button.copyWith(color: Colors.white, fontSize: 16.sp),
                  ),
                ),
              ),
              SizedBox(height: AppSpacing.gridGap),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMethodologyItem(
    BuildContext context, {
    required String icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 50.w,
          height: 50.w,
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12.r),
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
                style: AppTypography.h2.copyWith(color: isDark ? Colors.white : AppColors.textDark, fontSize: 18.sp),
              ),
              SizedBox(height: 4.h),
              Text(
                description,
                style: AppTypography.body.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textGray,
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
