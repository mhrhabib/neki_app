import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../components/app_background_widget.dart';
import '../../../../core/di/set_up_di.dart';
import '../../../../core/services/iap_service.dart';
import '../../domain/repositories/premium_repository.dart';

class PaywallScreen extends StatefulWidget {
  const PaywallScreen({super.key});

  @override
  State<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends State<PaywallScreen> {
  final IAPService _iapService = getIt<IAPService>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initIAP();
  }

  Future<void> _initIAP() async {
    setState(() => _isLoading = true);
    await _iapService.initialize();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handlePurchase(String productId) async {
    setState(() => _isLoading = true);
    try {
      final product = _iapService.products.firstWhere(
        (p) => p.id == productId,
        orElse: () => _iapService.products.first,
      );
      await _iapService.buyProduct(product);
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleRestore() async {
    setState(() => _isLoading = true);
    try {
      // For trial/demo purposes: Restore temporarily grants premium
      await getIt<PremiumRepository>().setPremium(true);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Premium Restored successfully!'),
            backgroundColor: AppColors.primaryGreen,
          ),
        );
        context.pop(); // Go back to see the results
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to restore.')));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          appBackgroundWidget(),

          // Background Glows
          Positioned(
            top: -100.h,
            right: -50.w,
            child: _buildGlowCircle(
              AppColors.goldAccent.withValues(alpha: 0.1),
            ),
          ),
          Positioned(
            bottom: -50.h,
            left: -50.w,
            child: _buildGlowCircle(
              AppColors.primaryGreen.withValues(alpha: 0.1),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 24.w),
                    child: Column(
                      children: [
                        SizedBox(height: 20.h),
                        _buildHeroSection(),
                        SizedBox(height: 32.h),
                        _buildComparisonTable(),
                        SizedBox(height: 40.h),
                        _buildPricingOptions(),
                        SizedBox(height: 32.h),
                        _buildFeaturesGrid(),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
                _buildFooter(),
              ],
            ),
          ),

          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CupertinoActivityIndicator(
                  color: AppColors.goldAccent,
                  radius: 15,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGlowCircle(Color color) {
    return Container(
      width: 300.w,
      height: 300.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 150, spreadRadius: 50)],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white54),
          ),
          TextButton(
            onPressed: _handleRestore,
            child: Text(
              'Restore',
              style: TextStyle(
                color: AppColors.goldAccent.withValues(alpha: 0.7),
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection() {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: AppColors.goldAccent.withValues(alpha: 0.1),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.goldAccent.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(
            Icons.workspace_premium_rounded,
            size: 48.sp,
            color: AppColors.goldAccent,
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'Neki Premium',
          style: GoogleFonts.sanchez(
            fontSize: 32.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Elevate your spiritual discipline',
          style: TextStyle(color: Colors.white54, fontSize: 16.sp),
        ),
      ],
    );
  }

  Widget _buildComparisonTable() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          _buildRow('Features', 'Free', 'Premium', isHeader: true),
          SizedBox(height: 12.h),
          const Divider(color: Colors.white10),
          _buildRow('Daily Prayer Lock', '2 Prayers', 'All 5'),
          _buildRow('Habit Challenges', 'Basic', 'Full Access'),
          _buildRow('Addiction Recovery', '7 Days', 'Unlimited'),
          _buildRow('Ad-Free Experience', 'No', 'Yes'),
          _buildRow('Detailed Stats', 'Basic', 'Pro Insights'),
        ],
      ),
    );
  }

  Widget _buildRow(
    String title,
    String free,
    String premium, {
    bool isHeader = false,
  }) {
    final style = TextStyle(
      fontSize: 13.sp,
      fontWeight: isHeader ? FontWeight.w900 : FontWeight.w500,
      color: isHeader ? AppColors.goldAccent : Colors.white70,
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(title, style: style)),
          Expanded(
            flex: 2,
            child: Text(
              free,
              style: style.copyWith(color: Colors.white24),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              premium,
              style: style.copyWith(
                color: isHeader ? Colors.white70 : AppColors.goldAccent,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingOptions() {
    return Column(
      children: [
        _buildPricingCard(
          id: IAPService.yearlyId,
          title: 'Yearly Plan',
          price: 'Save 40%',
          description: 'Best for long-term discipline',
          isPopular: true,
        ),
        SizedBox(height: 16.h),
        _buildPricingCard(
          id: IAPService.monthlyId,
          title: 'Monthly Plan',
          price: 'Flexible',
          description: 'Start your journey',
          isPopular: false,
        ),
      ],
    );
  }

  Widget _buildPricingCard({
    required String id,
    required String title,
    required String price,
    required String description,
    required bool isPopular,
  }) {
    return GestureDetector(
      onTap: () => _handlePurchase(id),
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isPopular
              ? AppColors.goldAccent.withValues(alpha: 0.1)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isPopular
                ? AppColors.goldAccent.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.1),
            width: isPopular ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (isPopular) ...[
                        SizedBox(width: 8.w),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.goldAccent,
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'POPULAR',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(color: Colors.white54, fontSize: 13.sp),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    color: AppColors.goldAccent,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Get Started',
                  style: TextStyle(color: Colors.white38, fontSize: 11.sp),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16.w,
      crossAxisSpacing: 16.w,
      childAspectRatio: 1.5,
      children: [
        _buildMiniFeature(Icons.lock_clock, 'Salah Lock', 'Unbreakable focus'),
        _buildMiniFeature(Icons.auto_graph, 'Pro Stats', 'Visualize growth'),
        _buildMiniFeature(Icons.shield_moon, 'Addiction', 'Recovery path'),
        _buildMiniFeature(Icons.groups, 'Groups', 'Coming soon'),
      ],
    );
  }

  Widget _buildMiniFeature(IconData icon, String title, String sub) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.goldAccent, size: 18.sp),
          const Spacer(),
          Text(
            title,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            sub,
            style: TextStyle(color: Colors.white38, fontSize: 10.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.all(24.h),
      child: Text(
        'Cancel anytime in your App Store settings.\nTerms of Service & Privacy Policy.',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.white24, fontSize: 11.sp),
      ),
    );
  }
}
