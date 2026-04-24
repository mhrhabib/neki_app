import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../components/app_background_widget.dart';
import '../../../../core/di/set_up_di.dart';
import '../../../../core/services/iap_service.dart';

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

  Future<void> _handleSupport(String productId) async {
    setState(() => _isLoading = true);
    try {
      final product = _iapService.products.firstWhere(
        (p) => p.id == productId,
        orElse: () => _iapService.products.first,
      );
      await _iapService.buySupport(product);
    } catch (_) {}
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
                        _buildMissionCard(),
                        SizedBox(height: 24.h),
                        _buildServerGoalBar(),
                        SizedBox(height: 40.h),
                        _buildSupportTiers(),
                        SizedBox(height: 40.h),
                        _buildWhySupportSection(),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
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
        children: [
          IconButton(
            onPressed: () => context.pop(),
            icon: const Icon(Icons.close_rounded, color: Colors.white54),
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
            Icons.favorite_rounded,
            size: 48.sp,
            color: AppColors.goldAccent,
          ),
        ),
        SizedBox(height: 24.h),
        Text(
          'Support Neki',
          style: GoogleFonts.sanchez(
            fontSize: 32.sp,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            letterSpacing: -0.5,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'A community-funded mission',
          style: TextStyle(color: Colors.white54, fontSize: 16.sp),
        ),
      ],
    );
  }

  Widget _buildMissionCard() {
    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            'Everything is Free',
            style: TextStyle(
              color: AppColors.goldAccent,
              fontSize: 18.sp,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'We have removed all paywalls. Neki is now 100% free for everyone, forever. Your support helps us cover server costs, development, and keeping the app ad-free for the entire Ummah.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14.sp,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerGoalBar() {
    const double current = 120;
    const double goal = 300;
    const double progress = current / goal;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Server Goal Progress',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${current.toInt()} / \$${goal.toInt()} raised',
                style: TextStyle(
                  color: AppColors.goldAccent,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Stack(
            children: [
              Container(
                height: 10.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(5.r),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 10.h,
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.goldAccent, Color(0xFFFFD700)],
                      ),
                      borderRadius: BorderRadius.circular(5.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.goldAccent.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            'Help us cover this month\'s costs to keep Neki alive!',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 12.sp,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportTiers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CHOOSE A SUPPORT TIER (SADAQAH)',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 16.h),
        _buildSupportCard(
          id: IAPService.support5Id,
          title: 'Supporter',
          price: '\$5',
          description: 'Help us grow Neki',
          isPopular: true,
        ),
        SizedBox(height: 12.h),
        _buildSupportCard(
          id: IAPService.support1Id,
          title: 'Buy us a Coffee',
          price: '\$1',
          description: 'A small gift to the devs',
          isPopular: false,
        ),
        SizedBox(height: 12.h),
        _buildSupportCard(
          id: IAPService.support10Id,
          title: 'Neki Partner',
          price: '\$10',
          description: 'Become a major contributor',
          isPopular: false,
        ),
      ],
    );
  }

  Widget _buildSupportCard({
    required String id,
    required String title,
    required String price,
    required String description,
    required bool isPopular,
  }) {
    return GestureDetector(
      onTap: () => _handleSupport(id),
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
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    description,
                    style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
            Text(
              price,
              style: TextStyle(
                color: AppColors.goldAccent,
                fontSize: 18.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhySupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHERE DOES THE MONEY GO?',
          style: TextStyle(
            color: Colors.white38,
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 20.h),
        _buildWhyItem(
          Icons.dns_rounded,
          'Server & API Costs',
          'Keeping the app fast and reliable 24/7.',
        ),
        _buildWhyItem(
          Icons.code_rounded,
          'Continuous Development',
          'Building new tools for your spiritual growth.',
        ),
        _buildWhyItem(
          Icons.block_rounded,
          'Zero Ads',
          'Keeping the experience pure and focused.',
        ),
      ],
    );
  }

  Widget _buildWhyItem(IconData icon, String title, String sub) {
    return Padding(
      padding: EdgeInsets.only(bottom: 20.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.primaryGreen.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: AppColors.primaryGreen, size: 20.sp),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  sub,
                  style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
