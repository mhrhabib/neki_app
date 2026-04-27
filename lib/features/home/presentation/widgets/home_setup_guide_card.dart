import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:neki_app/core/routes/route_names.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../salah_lock/presentation/cubit/salah_lock_cubit.dart';

class HomeSetupGuideCard extends StatelessWidget {
  const HomeSetupGuideCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalahLockCubit, SalahLockState>(
      builder: (context, state) {
        if (!state.showSetupGuide) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.goldAccent.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text('🛡️', style: TextStyle(fontSize: 22.sp)),
                      SizedBox(width: 12.w),
                      Text(
                        'Fortify Your Salah',
                        style: TextStyle(
                          color: AppColors.goldAccent,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () =>
                        context.read<SalahLockCubit>().dismissGuide(),
                    icon: Icon(Icons.close, color: Colors.white38, size: 20.sp),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Text(
                'Enable Salah Lock to stay focused and build an unbreakable prayer streak. Your phone will gently nudge you until your prayer is complete.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13.sp,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
              SizedBox(height: 20.h),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Navigate to settings using GoRouter
                        context.push(RouteNames.salahLockSettings);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.goldAccent,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        padding: EdgeInsets.symmetric(vertical: 12.h),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                      ),
                      child: Text(
                        'Set Up Now',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12.w),
                  TextButton(
                    onPressed: () =>
                        context.read<SalahLockCubit>().dismissGuide(),
                    child: Text(
                      'Maybe Later',
                      style: TextStyle(
                        color: Colors.white38,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
