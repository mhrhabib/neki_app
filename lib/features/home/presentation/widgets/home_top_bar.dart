import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../core/location/cubit/location_cubit.dart';
import '../../../../core/location/cubit/location_state.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../salah_lock/presentation/cubit/salah_lock_cubit.dart';

/// Top app bar showing the user's location pill on the left
/// and a circular profile icon on the right.
class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_LocationPill(), _ProfileIcon()],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private sub-widgets
// ---------------------------------------------------------------------------

class _LocationPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LocationCubit, LocationState>(
      builder: (context, state) {
        final locationText = switch (state) {
          LocationLoaded() => state.address,
          LocationError() => 'Location Error',
          _ => 'Fetching...',
        };

        return Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                CupertinoIcons.location_fill,
                color: Colors.white70,
                size: 12.sp,
              ),
              SizedBox(width: 4.w),
              Text(
                locationText,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ProfileIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SalahLockCubit, SalahLockState>(
      builder: (context, state) {
        final bool showPulse = state.showSetupGuide;

        return GestureDetector(
          onTap: () => GoRouter.of(context).push(RouteNames.salahLockSettings),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 36.w,
                height: 36.w,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: showPulse
                        ? AppColors.goldAccent.withValues(alpha: 0.5)
                        : Colors.white.withValues(alpha: 0.2),
                    width: showPulse ? 1.5.w : 1.w,
                  ),
                ),
                child: Icon(
                  CupertinoIcons.person_fill,
                  color: showPulse ? AppColors.goldAccent : Colors.white70,
                  size: 18.sp,
                ),
              ),
              if (showPulse)
                Positioned(
                  top: -2.r,
                  right: -2.r,
                  child: Container(
                    width: 10.r,
                    height: 10.r,
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF0D2818),
                        width: 2.r,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.goldAccent.withValues(alpha: 0.5),
                          blurRadius: 4.r,
                          spreadRadius: 1.r,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
