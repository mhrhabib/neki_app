import 'dart:ui';
import 'package:flutter/cupertino.dart';
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

class _PremiumOnboardingScreenState extends State<PremiumOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final IAPService _iapService = getIt<IAPService>();
  int _currentPage = 0;
  bool _isLoading = false;

  static const _totalPages = 4;

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
      _navigateToGoalSelection();
      return;
    }

    setState(() => _isLoading = true);
    try {
      final product = _iapService.products.firstWhere(
        (p) => p.id == IAPService.yearlyId,
        orElse: () => _iapService.products.first,
      );
      await _iapService.buyProduct(product);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);
    try {
      await _iapService.restorePurchases();
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  void _navigateToGoalSelection() {
    context.go(RouteNames.login);
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          appBackgroundWidget(),

          // Subtle background glow
          Positioned(
            top: -80.h,
            right: -60.w,
            child: Container(
              width: 300.w,
              height: 300.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.goldAccent.withValues(alpha: 0.08),
                    blurRadius: 150,
                    spreadRadius: 50,
                  ),
                ],
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Skip button — always visible except on last page
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_currentPage < _totalPages - 1)
                        CupertinoButton(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          onPressed: _navigateToGoalSelection,
                          child: Text(
                            'Skip',
                            style: TextStyle(
                              color: Colors.white38,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      else
                        SizedBox(height: 40.h),
                    ],
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildWelcomePage(),
                      _buildFeaturesPage(),
                      _buildSalahLockPage(),
                      _buildGetStartedPage(),
                    ],
                  ),
                ),

                // Bottom area
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 16.h, 24.w, 24.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPageIndicator(),
                      SizedBox(height: 24.h),
                      _buildActionButton(),
                      if (_currentPage == _totalPages - 1) ...[
                        SizedBox(height: 12.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSecondaryButton(
                              'Restore Purchase',
                              _handleRestore,
                            ),
                            SizedBox(width: 24.w),
                            _buildSecondaryButton(
                              'Continue Free',
                              _navigateToGoalSelection,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: AppColors.goldAccent),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Page 1: Welcome ─────────────────────────────────────────────────────

  Widget _buildWelcomePage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App icon / logo
          Container(
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(28.r),
              border: Border.all(
                color: AppColors.goldAccent.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Image.asset('assets/kabba_1.png', height: 60.h),
            ),
          ),
          SizedBox(height: 40.h),
          Text(
            'Your Daily\nCompanion for Deen',
            style: GoogleFonts.sanchez(
              fontSize: 30.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Text(
            'Track your prayers, build spiritual habits,\nand earn Neki points every day.',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white54,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 80.h),
        ],
      ),
    );
  }

  // ─── Page 2: Features ─────────────────────────────────────────────────────

  Widget _buildFeaturesPage() {
    final features = [
      _FeatureItem(
        icon: Icons.mosque_rounded,
        color: const Color(0xFF4ADE80),
        title: '5 Daily Prayers',
        subtitle: 'Never miss a salah with smart reminders',
      ),
      _FeatureItem(
        icon: Icons.local_fire_department_rounded,
        color: const Color(0xFFEF4444),
        title: 'Streaks & Points',
        subtitle: 'Build consistency and earn Neki rewards',
      ),
      _FeatureItem(
        icon: Icons.menu_book_rounded,
        color: const Color(0xFF60A5FA),
        title: 'Dhikr & Quran',
        subtitle: 'Daily remembrance with guided sessions',
      ),
      _FeatureItem(
        icon: Icons.emoji_events_rounded,
        color: AppColors.goldAccent,
        title: 'Leaderboard',
        subtitle: 'Compete with friends and stay motivated',
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Everything You Need',
              style: GoogleFonts.sanchez(
                fontSize: 26.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'All your ibadah in one place',
              style: TextStyle(fontSize: 15.sp, color: Colors.white38),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.h),
            ...features.map((f) => Padding(
                  padding: EdgeInsets.only(bottom: 16.h),
                  child: _buildFeatureRow(f),
                )),
            SizedBox(height: 60.h),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(_FeatureItem feature) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: feature.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Icon(feature.icon, color: feature.color, size: 24.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  feature.title,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  feature.subtitle,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Page 3: Salah Lock ───────────────────────────────────────────────────

  Widget _buildSalahLockPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Shield icon
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 130.w,
                  height: 130.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.goldAccent.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                ),
                Container(
                  width: 100.w,
                  height: 100.w,
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.shield_rounded,
                    size: 50.sp,
                    color: AppColors.goldAccent,
                  ),
                ),
              ],
            ),
            SizedBox(height: 40.h),
            Text(
              'Salah Lock Mode',
              style: GoogleFonts.sanchez(
                fontSize: 28.sp,
                fontWeight: FontWeight.w900,
                color: AppColors.goldAccent,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Your phone becomes your ally',
              style: TextStyle(fontSize: 15.sp, color: Colors.white38),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 36.h),
            _buildLockFeature(
              Icons.lock_clock_rounded,
              'Apps lock automatically at prayer time',
            ),
            SizedBox(height: 16.h),
            _buildLockFeature(
              Icons.auto_stories_rounded,
              'Read a Quran verse before unlocking',
            ),
            SizedBox(height: 16.h),
            _buildLockFeature(
              Icons.verified_rounded,
              'Confirm your salah to regain access',
            ),
            SizedBox(height: 24.h),
            // Quran verse
            ClipRRect(
              borderRadius: BorderRadius.circular(16.r),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: AppColors.goldAccent.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '"Indeed, prayer prohibits immorality\nand wrongdoing."',
                        style: GoogleFonts.sanchez(
                          fontSize: 14.sp,
                          color: Colors.white70,
                          fontStyle: FontStyle.italic,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        '— Al-Ankabut 29:45',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: AppColors.goldAccent.withValues(alpha: 0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 60.h),
          ],
        ),
      ),
    );
  }

  Widget _buildLockFeature(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 36.w,
          height: 36.w,
          decoration: BoxDecoration(
            color: AppColors.goldAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(icon, color: AppColors.goldAccent, size: 18.sp),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Page 4: Get Started ──────────────────────────────────────────────────

  Widget _buildGetStartedPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.workspace_premium_rounded,
              size: 80.sp,
              color: AppColors.goldAccent,
            ),
            SizedBox(height: 32.h),
            Text(
              'Unlock Full\nDiscipline',
              style: GoogleFonts.sanchez(
                fontSize: 30.sp,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Try Premium free for 7 days',
              style: TextStyle(
                fontSize: 16.sp,
                color: AppColors.goldAccent,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 36.h),
            _buildComparisonTable(),
            SizedBox(height: 16.h),
            Text(
              'Cancel anytime. No commitment.',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.white24,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40.h),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              _buildCompactRow('Feature', 'Free', 'Pro', isHeader: true),
              Divider(color: Colors.white.withValues(alpha: 0.06), height: 24.h),
              _buildCompactRow('Prayer Locks', '2', 'All 5'),
              _buildCompactRow('Streak Tracking', '—', '✓'),
              _buildCompactRow('Full App Blocker', '—', '✓'),
              _buildCompactRow('Custom Verses', '—', '✓'),
              _buildCompactRow('Ad-Free', '—', '✓'),
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
    final baseStyle = TextStyle(
      fontSize: isHeader ? 13.sp : 13.sp,
      fontWeight: isHeader ? FontWeight.w800 : FontWeight.w500,
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              feature,
              style: baseStyle.copyWith(
                color: isHeader ? AppColors.goldAccent : Colors.white70,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              free,
              style: baseStyle.copyWith(color: Colors.white24),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              pro,
              style: baseStyle.copyWith(
                color: isHeader ? Colors.white70 : AppColors.goldAccent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared Widgets ───────────────────────────────────────────────────────

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        _totalPages,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: _currentPage == index ? 28.w : 8.w,
          height: 5.h,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? AppColors.goldAccent
                : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton() {
    final isLastPage = _currentPage == _totalPages - 1;
    final label = isLastPage ? 'Start Free Trial' : 'Continue';

    return SizedBox(
      width: double.infinity,
      height: 56.h,
      child: ElevatedButton(
        onPressed: isLastPage ? _handlePurchase : _nextPage,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldAccent,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          elevation: 0,
        ),
        child: Text(
          label.toUpperCase(),
          style: GoogleFonts.sanchez(
            fontSize: 15.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return CupertinoButton(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      onPressed: onPressed,
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white30,
          fontSize: 12.sp,
          decoration: TextDecoration.underline,
          decorationColor: Colors.white30,
        ),
      ),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _FeatureItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}
