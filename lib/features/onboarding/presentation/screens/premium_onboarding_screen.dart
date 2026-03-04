import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../components/app_background_widget.dart';

import '../../../../core/di/set_up_di.dart';
import '../../../../core/services/iap_service.dart';

class PremiumOnboardingScreen extends StatefulWidget {
  const PremiumOnboardingScreen({super.key});

  @override
  State<PremiumOnboardingScreen> createState() =>
      _PremiumOnboardingScreenState();
}

class _PremiumOnboardingScreenState extends State<PremiumOnboardingScreen> {
  final PageController _pageController = PageController();
  final IAPService _iapService = getIt<IAPService>();
  int _currentPage = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initIAP();
  }

  Future<void> _initIAP() async {
    await _iapService.initialize();
    if (mounted) setState(() {});
  }

  Future<void> _handlePurchase() async {
    if (_iapService.products.isEmpty) {
      // Products not loaded or unavailable
      context.go(RouteNames.goalSelection);
      return;
    }

    setState(() => _isLoading = true);
    try {
      // By default buy yearly if available, else first available
      final product = _iapService.products.firstWhere(
        (p) => p.id == IAPService.yearlyId,
        orElse: () => _iapService.products.first,
      );
      await _iapService.buyProduct(product);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);
    try {
      await _iapService.restorePurchases();
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          appBackgroundWidget(),

          // Background Decorative Glows
          AnimatedPositioned(
            duration: const Duration(seconds: 2),
            top: _currentPage % 2 == 0 ? -100.h : 400.h,
            right: _currentPage % 2 == 0 ? -100.w : 200.w,
            child: _buildGlow(AppColors.goldAccent.withValues(alpha: 0.15)),
          ),
          AnimatedPositioned(
            duration: const Duration(seconds: 2),
            bottom: _currentPage % 2 == 0 ? 300.h : -100.h,
            left: _currentPage % 2 == 0 ? 200.w : -100.w,
            child: _buildGlow(Colors.greenAccent.withValues(alpha: 0.1)),
          ),

          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            physics: const BouncingScrollPhysics(),
            children: [
              _buildEmotionalHook(),
              _buildTheProblem(),
              _buildTheSolution(),
              _buildSpiritualReinforcement(),
              _buildPremiumPower(),
              _buildUrgencyTrial(),
              _buildFinalClose(),
            ],
          ),

          // Loading Indicator
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.goldAccent),
              ),
            ),

          // Bottom Navigation Area
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24.w, 20.h, 24.w, 50.h),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0),
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black,
                  ],
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildPageIndicator(),
                  SizedBox(height: 32.h),
                  _buildActionButton(),
                  if (_currentPage >= 4) ...[
                    SizedBox(height: 16.h),
                    _buildRestoreButton(),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlow(Color color) {
    return Container(
      width: 400.w,
      height: 400.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 150, spreadRadius: 50)],
      ),
    );
  }

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        7,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: _currentPage == index ? 32.w : 8.w,
          height: 6.h,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.goldAccent
                : Colors.white12,
            borderRadius: BorderRadius.circular(10.r),
            boxShadow: _currentPage == index
                ? [
                    BoxShadow(
                      color: AppColors.goldAccent.withValues(alpha: 0.4),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    String label = 'Continue';
    if (_currentPage == 0) label = 'I want to fix this';
    if (_currentPage == 1) label = 'Show me how';
    if (_currentPage == 2) label = 'This is powerful';
    if (_currentPage == 3) label = 'I want protection';
    if (_currentPage == 4) label = 'Unlock Full Discipline';
    if (_currentPage == 5) label = 'Start Free Trial';
    if (_currentPage == 6) label = 'Protect My Salah';

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldAccent.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          if (_currentPage < 5) {
            _pageController.nextPage(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutQuart,
            );
          } else if (_currentPage == 5 || _currentPage == 6) {
            _handlePurchase();
          } else {
            context.go(RouteNames.goalSelection);
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldAccent,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(vertical: 18.h),
          minimumSize: Size(double.infinity, 60.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          elevation: 0,
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.sanchez(
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildRestoreButton() {
    return TextButton(
      onPressed: _handleRestore,
      child: Text(
        'Restore Purchase',
        style: TextStyle(
          color: Colors.white38,
          fontSize: 12.sp,
          decoration: TextDecoration.underline,
        ),
      ),
    );
  }

  // --- Individual Screens ---

  Widget _buildEmotionalHook() {
    return _OnboardingContent(
      title: 'How many prayers have you delayed because of your phone?',
      subtitle:
          'Your screen time is increasing.\nYour Salah focus is decreasing.',
      iconWidget: _buildPhoneGlowIcon(),
    );
  }

  Widget _buildPhoneGlowIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 120.w,
          height: 120.w,
          decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
        ),
        Icon(Icons.phone_android_rounded, size: 80.sp, color: Colors.white70),
        Positioned(
          top: 20,
          right: 20,
          child: Container(
            padding: EdgeInsets.all(6.r),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              '99+',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTheProblem() {
    return _OnboardingContent(
      title: 'Your phone controls your time.',
      subtitle:
          'Endless scrolling. Notifications during Salah. "5 minutes" becomes 1 hour.\n\nYou don’t need another reminder app.\nYou need discipline.',
      iconWidget: Icon(
        Icons.timer_off_rounded,
        size: 100.sp,
        color: Colors.orangeAccent,
      ),
    );
  }

  Widget _buildTheSolution() {
    return _OnboardingContent(
      title: 'Lock Your Apps at Salah Time',
      subtitle:
          '✔ Apps lock automatically at prayer times\n✔ Short Qur’an verse before unlocking\n✔ Confirm Salah before access',
      iconWidget: _buildLockAnimation(),
    );
  }

  Widget _buildLockAnimation() {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 140.w,
          height: 140.w,
          decoration: BoxDecoration(
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.3),
              width: 2,
            ),
            shape: BoxShape.circle,
          ),
        ),
        Icon(Icons.shield_rounded, size: 90.sp, color: AppColors.goldAccent),
        Icon(Icons.lock_rounded, size: 40.sp, color: Colors.black54),
      ],
    );
  }

  Widget _buildSpiritualReinforcement() {
    return _OnboardingContent(
      title: '“Indeed, prayer prohibits immorality and wrongdoing.”',
      subtitle:
          '— Al-Ankabut 29:45\n\nYour phone can either distract you…\nOr protect you.',
      iconWidget: Icon(
        Icons.auto_stories_rounded,
        size: 100.sp,
        color: Colors.greenAccent,
      ),
    );
  }

  Widget _buildPremiumPower() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'TAKE FULL CONTROL',
            style: GoogleFonts.sanchez(
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.goldAccent,
              letterSpacing: 2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Unlock Premium Discipline',
            style: TextStyle(color: Colors.white38, fontSize: 14.sp),
          ),
          SizedBox(height: 40.h),
          _buildComparisonTable(),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _buildCompactRow('Feature', 'Free', 'Pro', isHeader: true),
              const Divider(color: Colors.white10),
              _buildCompactRow('5 Prayer Locks', '2 only', 'ALL'),
              _buildCompactRow('Custom Verses', '❌', '✅'),
              _buildCompactRow('Streak Tracking', '❌', '✅'),
              _buildCompactRow('App Blocker', 'Limited', 'FULL'),
              _buildCompactRow('Ad-Free', '❌', '✅'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactRow(
    String feature,
    String free,
    String pro, {
    bool isHeader = false,
  }) {
    final style = TextStyle(
      color: isHeader ? AppColors.goldAccent : Colors.white70,
      fontSize: isHeader ? 14.sp : 13.sp,
      fontWeight: isHeader ? FontWeight.w900 : FontWeight.w500,
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(feature, style: style)),
          Expanded(
            flex: 1,
            child: Text(
              free,
              style: style.copyWith(color: isHeader ? null : Colors.white38),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              pro,
              style: style.copyWith(
                color: isHeader ? null : AppColors.goldAccent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUrgencyTrial() {
    return _OnboardingContent(
      title: 'Start Your 7-Day Discipline Challenge',
      subtitle:
          'Try Premium FREE for 7 days.\nBuild the habit. Keep the reward.\n\nChoose your path to discipline.',
      iconWidget: _buildTrialBadge(),
    );
  }

  Widget _buildTrialBadge() {
    return Container(
      padding: EdgeInsets.all(24.r),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.workspace_premium_rounded,
        size: 100.sp,
        color: AppColors.goldAccent,
      ),
    );
  }

  Widget _buildFinalClose() {
    return _OnboardingContent(
      title: 'Imagine 30 days of never missing Salah.',
      subtitle:
          'Your discipline starts today.\nProtect your time for Allah.\n\nCancel anytime.',
      iconWidget: Icon(
        Icons.verified_user_rounded,
        size: 100.sp,
        color: Colors.blueAccent,
      ),
    );
  }
}

class _OnboardingContent extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget iconWidget;

  const _OnboardingContent({
    required this.title,
    required this.subtitle,
    required this.iconWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 40.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(seconds: 1),
            curve: Curves.easeOutBack,
            builder: (context, value, child) =>
                Transform.scale(scale: value, child: child),
            child: iconWidget,
          ),
          SizedBox(height: 50.h),
          Text(
            title,
            style: GoogleFonts.sanchez(
              fontSize: 28.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white60,
              height: 1.6,
              fontWeight: FontWeight.w300,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 100.h), // Space for bottom buttons
        ],
      ),
    );
  }
}
