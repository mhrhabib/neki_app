import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/route_names.dart';
import '../../../challenge/presentation/cubit/challenge_cubit.dart';

/// Two side-by-side feature cards:
///  • Addiction Recovery
///  • Best Satan Challenge (daily goal builder)
class HomeFeatureCards extends StatelessWidget {
  const HomeFeatureCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: BlocBuilder<ChallengeCubit, ChallengeState>(
        builder: (context, state) {
          return Row(
            children: [
              Expanded(child: _AddictionCard(state: state)),
              SizedBox(width: 12.w),
              Expanded(child: _ChallengeCard(state: state)),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private card widgets
// ---------------------------------------------------------------------------

class _AddictionCard extends StatelessWidget {
  final ChallengeState state;

  const _AddictionCard({required this.state});

  bool get _hasActive =>
      state is ChallengeLoaded &&
      (state as ChallengeLoaded).hasActiveChallenge &&
      (state as ChallengeLoaded).challenge != null &&
      (state as ChallengeLoaded).challenge!.challengeType != null &&
      (state as ChallengeLoaded).challenge!.challengeType!.startsWith(
        'addiction_',
      );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        _hasActive ? RouteNames.habitBuilding : RouteNames.addiction,
      ),
      child: Container(
        height: 140.h,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E4D35), Color(0xFF0D2818)],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Text('🕌', style: TextStyle(fontSize: 40.sp)),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _CardContent(
                title: 'Addiction Recover',
                subtitle: _hasActive
                    ? 'View your plan'
                    : 'Start a recover plan',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChallengeCard extends StatelessWidget {
  final ChallengeState state;

  const _ChallengeCard({required this.state});

  bool get _hasActive {
    if (state is! ChallengeLoaded) return false;
    final loaded = state as ChallengeLoaded;
    return loaded.hasActiveChallenge &&
        (loaded.challenge?.challengeType == null ||
            !loaded.challenge!.challengeType!.startsWith('addiction_'));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(
        _hasActive ? RouteNames.habitBuilding : RouteNames.goalSelection,
      ),
      child: Container(
        height: 140.h,
        padding: EdgeInsets.all(14.w),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A3D50), Color(0xFF0D2030)],
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              right: 0,
              child: Text('🕋', style: TextStyle(fontSize: 40.sp)),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _CardContent(
                title: 'Best Satan Challeng',
                subtitle: _hasActive
                    ? 'Continue your journey'
                    : 'Start buiding you daily neki',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Shared bottom section used inside both feature cards.
class _CardContent extends StatelessWidget {
  final String title;
  final String subtitle;

  const _CardContent({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          subtitle,
          style: TextStyle(color: Colors.white60, fontSize: 10.sp),
        ),
        SizedBox(height: 8.h),
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: const Color(0xFF4ADE80).withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.arrow_forward,
            color: const Color(0xFF4ADE80),
            size: 12.sp,
          ),
        ),
      ],
    );
  }
}
