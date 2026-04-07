import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/routes/route_names.dart';
import '../../../challenge/presentation/cubit/challenge_cubit.dart';

/// Two side-by-side feature cards with a premium glassmorphic design:
///  • Addiction Recovery
///  • Best Satan Challenge (daily goal builder)
class HomeFeatureCards extends StatelessWidget {
  const HomeFeatureCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: BlocBuilder<ChallengeCubit, ChallengeState>(
        builder: (context, state) {
          return Row(
            children: [
              Expanded(
                child: _FeatureCard(
                  title: 'Addiction\nRecovery',
                  subtitle: _isAddictionActive(state)
                      ? 'View your plan'
                      : 'Start recovery',
                  imagePath: 'assets/images/features/addiction_recovery.png',
                  onTap: () => context.push(
                    _isAddictionActive(state)
                        ? RouteNames.habitBuilding
                        : RouteNames.addiction,
                  ),
                  gradient: const [Color(0xFF1E4D35), Color(0xFF0D2818)],
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _FeatureCard(
                  title: 'Beat Satan\nChallenge',
                  subtitle: _isChallengeActive(state)
                      ? 'Continue journey'
                      : 'Build your neki',
                  imagePath: 'assets/images/features/satan_challenge.png',
                  onTap: () => context.push(
                    _isChallengeActive(state)
                        ? RouteNames.habitBuilding
                        : RouteNames.goalSelection,
                  ),
                  gradient: const [Color(0xFF1A3D50), Color(0xFF0D2030)],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isAddictionActive(ChallengeState state) {
    return state is ChallengeLoaded && state.hasType('addiction');
  }

  bool _isChallengeActive(ChallengeState state) {
    return state is ChallengeLoaded && state.hasType('beat_satan');
  }
}

class _FeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imagePath;
  final VoidCallback onTap;
  final List<Color> gradient;

  const _FeatureCard({
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.onTap,
    required this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160.h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background Image/Illustration (Full Bleed)
            Positioned.fill(child: Image.asset(imagePath, fit: BoxFit.cover)),

            // Gradient Overlay for Readability
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),

            // Subtle glass effect overlay on top of the image
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: gradient[0].withValues(alpha: 0.15),
                ),
              ),
            ),

            // Content
            Padding(
              padding: EdgeInsets.all(18.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(),
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          offset: const Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 14.h),
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.white,
                        size: 11.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
