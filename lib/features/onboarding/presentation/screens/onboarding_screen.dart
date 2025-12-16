import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import 'goal_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      icon: '🕌',
      title: 'Track Your Ibadah',
      description: 'Keep track of your daily prayers, fasts, and good deeds',
    ),
    OnboardingPage(icon: '⭐', title: 'Earn Neki Points', description: 'Get rewarded for every good deed you perform'),
    OnboardingPage(icon: '🏆', title: 'Compete Globally', description: 'See where you rank among Muslims worldwide'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : AppColors.softCream,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(_pages[index]),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(AppSpacing.outerPadding),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => Container(
                        margin: EdgeInsets.symmetric(horizontal: 4.w),
                        width: _currentPage == index ? 24.w : 8.w,
                        height: 8.h,
                        decoration: BoxDecoration(
                          color: _currentPage == index ? AppColors.primaryGreen : AppColors.dividerGray,
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: AppSpacing.gridGap),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => const GoalSelectionScreen()));
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryGreen,
                        padding: EdgeInsets.all(16.w),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.cornerRadius)),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                        style: AppTypography.button.copyWith(color: Colors.white),
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

  Widget _buildPage(OnboardingPage page) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.all(AppSpacing.outerPadding * 2),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(page.icon, style: TextStyle(fontSize: 80.sp)),
          SizedBox(height: AppSpacing.gridGap * 3),
          Text(
            page.title,
            style: AppTypography.h1.copyWith(color: isDark ? Colors.white : AppColors.primaryGreen),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: AppSpacing.gridGap),
          Text(
            page.description,
            style: AppTypography.body.copyWith(color: isDark ? Colors.white70 : AppColors.textGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}

class OnboardingPage {
  final String icon;
  final String title;
  final String description;

  OnboardingPage({required this.icon, required this.title, required this.description});
}
