import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../components/app_background_widget.dart';
import '../../../../core/di/set_up_di.dart';
import '../../../../core/services/iap_service.dart';
import '../../../../core/location/cubit/location_cubit.dart';
import '../../../beat_satan_chalange/presentation/cubit/onboarding_cubit.dart';
import '../../../auth/domain/repositories/premium_repository.dart';

class PremiumOnboardingScreen extends StatefulWidget {
  const PremiumOnboardingScreen({super.key});

  @override
  State<PremiumOnboardingScreen> createState() => _PremiumOnboardingScreenState();
}

class _PremiumOnboardingScreenState extends State<PremiumOnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  final IAPService _iapService = getIt<IAPService>();
  int _currentPage = 0;
  bool _isLoading = false;

  // Flow State
  String? _selectedPrimaryGoal;
  int _selectedChallengeIndex = 0; 
  bool _magicMomentFinished = false;

  static const _totalPages = 7;

  final List<Map<String, dynamic>> _challenges = [
    {
      'days': 7,
      'points': 100,
      'title': '7 Days Starter',
      'description': 'Prophet Muhammad (ﷺ) said: "The most beloved of deeds to Allah are those that are most consistent, even if they are small."',
      'icon': '🛡️',
    },
    {
      'days': 14,
      'points': 200,
      'title': '14 Days Warrior',
      'description': 'Strengthen your resolve and build momentum in your spiritual journey.',
      'icon': '⚔️',
    },
    {
      'days': 21,
      'points': 300,
      'title': '21 Days Champion',
      'description': 'Form a lasting habit that breaks the chains of negative influences.',
      'icon': '👑',
    },
  ];

  final List<String> _primaryGoals = [
    'Stop Social Media Addiction',
    'Pray 5 Times Daily',
    'Start Daily Dhikr',
    'Improve Focus in Salah',
  ];

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
      _completeFlowAndNavigate();
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

  void _completeFlowAndNavigate() {
    // Start the 7-day trial automatically upon completing onboarding
    getIt<PremiumRepository>().startTrial();
    context.read<OnboardingCubit>().completeOnboarding();
  }

  void _navigateToLogin() {
    context.push(RouteNames.login);
  }

  void _nextPage() {
    if (_currentPage < _totalPages - 1) {
      // If moving from Challenge Selection to Features, save the goal
      if (_currentPage == 2) {
        final challenge = _challenges[_selectedChallengeIndex];
        context.read<OnboardingCubit>().saveGoal(
          challenge['days'],
          challenge['points'],
        );
      }

      // If moving to Magic Moment, trigger the timer
      if (_currentPage == 4) {
        _startMagicMoment();
      }

      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  void _startMagicMoment() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _magicMomentFinished = true);
        _nextPage();
      }
    });
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
                // Skip area
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_currentPage < _totalPages - 1 && _currentPage != 5)
                        CupertinoButton(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 8.h,
                          ),
                          onPressed: _completeFlowAndNavigate,
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
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildWelcomePage(),
                      _buildDiscoveryPage(),
                      _buildGoalSelectionPage(),
                      _buildFeaturesPage(),
                      _buildLocationPermissionPage(),
                      _buildMagicMomentPage(),
                      _buildGetStartedPage(),
                    ],
                  ),
                ),

                // Bottom area
                Padding(
                  padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 24.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildPageIndicator(),
                      if (_currentPage == _totalPages - 1) ...[
                        SizedBox(height: 16.h),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildSecondaryButton(
                              'Restore Purchase',
                              _handleRestore,
                            ),
                            SizedBox(width: 24.w),
                            _buildSecondaryButton(
                              'Explore as Guest',
                              _completeFlowAndNavigate,
                            ),
                          ],
                        ),
                      ],
                      if (_currentPage == 0) ...[
                        SizedBox(height: 12.h),
                        _buildSecondaryButton(
                          'Already have an account? Login',
                          _navigateToLogin,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

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

  // ─── Step 1: Welcome ─────────────────────────────────────────────────────

  Widget _buildWelcomePage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
            'Welcome Your\nSpiritual Journey',
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
            'Track your prayers, build lasting habits,\nand earn Neki points.',
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.white54,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 48.h),
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'GET STARTED',
                style: GoogleFonts.sanchez(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 2: Discovery ──────────────────────────────────────────────────

  Widget _buildDiscoveryPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'What is your primary goal?',
            style: GoogleFonts.sanchez(
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'We will personalize your experience based on this.',
            style: TextStyle(fontSize: 14.sp, color: Colors.white38),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          ..._primaryGoals.map((goal) {
            final isSelected = _selectedPrimaryGoal == goal;
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedPrimaryGoal = goal);
                  Future.delayed(const Duration(milliseconds: 300), _nextPage);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.goldAccent.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.goldAccent
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          goal,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 16.sp,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.goldAccent,
                          size: 20.sp,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Step 3: Goal Selection ────────────────────────────────────

  Widget _buildGoalSelectionPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Challenge Yourself',
            style: GoogleFonts.sanchez(
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              color: AppColors.goldAccent,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            'Pick a duration to build consistency',
            style: TextStyle(fontSize: 14.sp, color: Colors.white38),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          ...List.generate(_challenges.length, (index) {
            final challenge = _challenges[index];
            final isSelected = _selectedChallengeIndex == index;
            return Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: GestureDetector(
                onTap: () {
                  setState(() => _selectedChallengeIndex = index);
                  Future.delayed(const Duration(milliseconds: 300), _nextPage);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: EdgeInsets.all(16.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.goldAccent.withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.goldAccent
                          : Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        challenge['icon'],
                        style: TextStyle(fontSize: 24.sp),
                      ),
                      SizedBox(width: 16.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              challenge['title'],
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.white70,
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Target: ${challenge['points']} Points',
                              style: TextStyle(
                                color: AppColors.goldAccent.withValues(alpha: 0.8),
                                fontSize: 12.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSelected)
                        Icon(
                          Icons.check_circle_rounded,
                          color: AppColors.goldAccent,
                          size: 24.sp,
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Step 4: Features ─────────────────────────────────────────────────────

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
        icon: Icons.emoji_events_rounded,
        color: AppColors.goldAccent,
        title: 'Leaderboard',
        subtitle: 'Compete with friends and stay motivated',
      ),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
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
          SizedBox(height: 40.h),
          ...features.map((f) => Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: _buildFeatureRow(f),
              )),
          SizedBox(height: 24.h),
          SizedBox(
            width: double.infinity,
            height: 56.h,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
              ),
              child: Text(
                'CONTINUE',
                style: GoogleFonts.sanchez(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ],
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
                Text(feature.subtitle, style: TextStyle(fontSize: 13.sp, color: Colors.white38)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 5: Location ──────────────────────────────────────────────────

  Widget _buildLocationPermissionPage() {
    final locCubit = getIt<LocationCubit>();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.location_on_rounded, size: 80.sp, color: AppColors.goldAccent),
          SizedBox(height: 32.h),
          Text(
            'Enable Location',
            style: GoogleFonts.sanchez(fontSize: 28.sp, fontWeight: FontWeight.w900, color: Colors.white),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Text(
            'Accurate Salah times require your location. We will use this to keep your schedule perfect.',
            style: TextStyle(fontSize: 16.sp, color: Colors.white54, height: 1.5),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                setState(() => _isLoading = true);
                try {
                  await locCubit.requestAndFetch();
                  if (mounted) _nextPage();
                } catch (_) {}
                if (mounted) setState(() => _isLoading = false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldAccent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 14.h),
                child: Text('Allow Location'.toUpperCase(), style: GoogleFonts.sanchez(fontWeight: FontWeight.w900)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Step 6: Magic Moment ──────────────────────────────────────────────

  Widget _buildMagicMomentPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 80.w,
            height: 80.w,
            child: _magicMomentFinished
                ? Icon(
                    Icons.check_circle_rounded,
                    color: AppColors.goldAccent,
                    size: 80.r,
                  )
                : CircularProgressIndicator(
                    color: AppColors.goldAccent,
                    strokeWidth: 6.r,
                  ),
          ),
          SizedBox(height: 48.h),
          Text(
            _magicMomentFinished
                ? 'Your Plan is Ready!'
                : 'Personalizing Your Path',
            style: GoogleFonts.sanchez(
              fontSize: 24.sp,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16.h),
          Text(
            _magicMomentFinished
                ? 'We have tailored the Neki point system to your personal goals.'
                : 'Designing a custom experience based on your habits...',
            style: TextStyle(
              fontSize: 15.sp,
              color: Colors.white54,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ─── Step 7: Paywall ──────────────────────────────────────────────────

  Widget _buildGetStartedPage() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 32.w),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.workspace_premium_rounded, size: 80.sp, color: AppColors.goldAccent),
            SizedBox(height: 32.h),
            Text(
              'Unlock Full\nDiscipline',
              style: GoogleFonts.sanchez(fontSize: 30.sp, fontWeight: FontWeight.w900, color: Colors.white, height: 1.2),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16.h),
            _buildComparisonTable(),
            SizedBox(height: 24.h),
            SizedBox(
              width: double.infinity,
              height: 56.h,
              child: ElevatedButton(
                onPressed: _handlePurchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                ),
                child: Text(
                  'START FREE TRIAL',
                  style: GoogleFonts.sanchez(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text('Try Premium free for 7 days. Cancel anytime.', style: TextStyle(fontSize: 12.sp, color: Colors.white24)),
            SizedBox(height: 24.h),
            _buildSecondaryButton('MAYBE LATER, EXPLORE FIRST', _completeFlowAndNavigate),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonTable() {
    return Container(
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
          _buildCompactRow('Ad-Free', '—', '✓'),
        ],
      ),
    );
  }

  Widget _buildCompactRow(String feature, String free, String pro, {bool isHeader = false}) {
    final baseStyle = TextStyle(fontSize: 13.sp, fontWeight: isHeader ? FontWeight.w800 : FontWeight.w500);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 6.h),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(feature, style: baseStyle.copyWith(color: isHeader ? AppColors.goldAccent : Colors.white70))),
          Expanded(flex: 1, child: Text(free, style: baseStyle.copyWith(color: Colors.white24), textAlign: TextAlign.center)),
          Expanded(flex: 1, child: Text(pro, style: baseStyle.copyWith(color: isHeader ? Colors.white70 : AppColors.goldAccent), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  // ─── Shared Widgets ───────────────────────────────────────────────────────

  Widget _buildPageIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_totalPages, (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          width: _currentPage == index ? 28.w : 8.w,
          height: 5.h,
          decoration: BoxDecoration(
            color: _currentPage == index ? AppColors.goldAccent : Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      ),
    );
  }


  Widget _buildSecondaryButton(String text, VoidCallback onPressed) {
    return CupertinoButton(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      onPressed: onPressed,
      child: Text(text, style: TextStyle(color: Colors.white30, fontSize: 12.sp, decoration: TextDecoration.underline, decorationColor: Colors.white30)),
    );
  }
}

class _FeatureItem {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  const _FeatureItem({required this.icon, required this.color, required this.title, required this.subtitle});
}
