import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/di/set_up_di.dart';
import '../../../points/domain/repositories/points_repository.dart';
import '../../../points/presentation/cubit/points_cubit.dart';
import '../../../challenge/domain/repositories/challenge_repository.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class GoodDeedsScreen extends StatefulWidget {
  const GoodDeedsScreen({super.key});

  @override
  State<GoodDeedsScreen> createState() => _GoodDeedsScreenState();
}

class _GoodDeedsScreenState extends State<GoodDeedsScreen> {
  DeedOption? _selectedDeed;
  final TextEditingController _notesController = TextEditingController();

  final List<DeedOption> _deedOptions = const [
    DeedOption(id: 'parents', title: 'Help Parents', icon: '👨‍👩‍👧', points: 30),
    DeedOption(id: 'charity', title: 'Charity', icon: '💝', points: 50),
    DeedOption(id: 'quran', title: 'Quran Recitation', icon: '📖', points: 40),
    DeedOption(id: 'volunteer', title: 'Volunteer', icon: '🤝', points: 60),
    DeedOption(id: 'kindness', title: 'Act of Kindness', icon: '💚', points: 25),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedDeed == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a good deed')));
      return;
    }

    // Get repositories
    final pointsRepository = getIt<PointsRepository>();
    final challengeRepository = getIt<ChallengeRepository>();

    // Get current user ID - with null safety
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;
    if (authState is! Authenticated) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please log in first')));
      return;
    }
    final userId = authState.user.id;

    // Capture selected deed locally to avoid null-safety issues inside async builders
    final deed = _selectedDeed!;

    // Capture PointsCubit to avoid using BuildContext across async gaps
    final pointsCubit = context.read<PointsCubit>();

    // Add points for the good deed and await completion
    await pointsRepository.addPoints(userId: userId, points: deed.points, source: 'good_deed_${deed.id}');

    // Refresh points to update UI after addPoints completes
    await pointsCubit.refreshPoints(userId);

    // Try to complete today's challenge if active (await to ensure ordering)
    try {
      final hasChallenge = await challengeRepository.hasActiveChallenge(userId);
      if (hasChallenge) {
        await challengeRepository.completeTodayChallenge(userId);
      }
    } catch (e) {
      // Challenge already completed today or other error, ignore
      debugPrint('Challenge completion skipped: $e');
    }

    // Refresh points again to pick up any challenge-awarded points
    await pointsCubit.refreshPoints(userId);

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Barakallah! 🌟'),
        content: Text('Your ${deed.title} has been recorded.\n+${deed.points} Neki points'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _selectedDeed = null;
                _notesController.clear();
              });
              context.pop();
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(20.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select Good Deed',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    _buildDeedOptions(),
                    SizedBox(height: 24.h),
                    _buildNotesSection(),
                  ],
                ),
              ),
            ),
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Icon(Icons.chevron_left, color: isDark ? Colors.white : const Color(0xFF1F2937)),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'Log Good Deed',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.primaryGreen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeedOptions() {
    return Column(children: _deedOptions.map((deed) => _buildDeedOption(deed)).toList());
  }

  Widget _buildDeedOption(DeedOption deed) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedDeed?.id == deed.id;

    return GestureDetector(
      onTap: () => setState(() => _selectedDeed = deed),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isSelected ? AppColors.primaryGreen : (isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB)),
            width: 2.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen.withValues(alpha: isDark ? 0.3 : 0.15)
                    : (isDark ? const Color(0xFF374151) : const Color(0xFFF9FAFB)),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Text(deed.icon, style: TextStyle(fontSize: 24.sp)),
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deed.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF1F2937),
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '+${deed.points} Neki',
                    style: TextStyle(fontSize: 12.sp, color: const Color(0xFFD4AF37), fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(color: AppColors.primaryGreen, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: Colors.white, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: _notesController,
          maxLines: 4,
          style: TextStyle(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            hintText: 'Add any details about your good deed...',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: isDark ? const Color(0xFF374151) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: AppColors.primaryGreen),
            ),
            contentPadding: EdgeInsets.all(16.w),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB), width: 1)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _selectedDeed != null ? _handleSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _selectedDeed != null ? AppColors.primaryGreen : const Color(0xFFD1D5DB),
            padding: EdgeInsets.symmetric(vertical: 16.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
            elevation: 0,
          ),
          child: Text(
            'Submit Good Deed',
            style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.w600),
          ),
        ),
      ),
    );
  }
}

class DeedOption {
  const DeedOption({required this.id, required this.title, required this.icon, required this.points});

  final String id;
  final String title;
  final String icon;
  final int points;
}
