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
import '../../../../components/app_background_widget.dart';

class GoodDeedsScreen extends StatefulWidget {
  const GoodDeedsScreen({super.key});

  @override
  State<GoodDeedsScreen> createState() => _GoodDeedsScreenState();
}

class _GoodDeedsScreenState extends State<GoodDeedsScreen> {
  DeedOption? _selectedDeed;
  final TextEditingController _notesController = TextEditingController();

  final List<DeedOption> _deedOptions = const [
    DeedOption(
      id: 'parents',
      title: 'Help Parents',
      icon: '👨‍👩‍👧',
      points: 30,
    ),
    DeedOption(id: 'charity', title: 'Charity', icon: '💝', points: 50),
    DeedOption(id: 'quran', title: 'Quran Recitation', icon: '📖', points: 40),
    DeedOption(id: 'volunteer', title: 'Volunteer', icon: '🤝', points: 60),
    DeedOption(
      id: 'kindness',
      title: 'Act of Kindness',
      icon: '💚',
      points: 25,
    ),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_selectedDeed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select a good deed'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
        ),
      );
      return;
    }

    final pointsRepository = getIt<PointsRepository>();
    final challengeRepository = getIt<ChallengeRepository>();
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;

    if (authState is! Authenticated) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please log in first')));
      return;
    }

    final userId = authState.user.id;
    final deed = _selectedDeed!;
    final pointsCubit = context.read<PointsCubit>();

    await pointsRepository.addPoints(
      userId: userId,
      points: deed.points,
      source: 'good_deed_${deed.id}',
    );

    await pointsCubit.refreshPoints(userId);

    try {
      final hasChallenge = await challengeRepository.hasActiveChallenge(userId);
      if (hasChallenge) {
        await challengeRepository.completeTodayChallenge(userId);
      }
    } catch (e) {
      debugPrint('Challenge completion skipped: $e');
    }

    await pointsCubit.refreshPoints(userId);

    if (!mounted) return;

    _showCompletionDialog(deed);
  }

  void _showCompletionDialog(DeedOption deed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Container(
        alignment: Alignment.center,
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.all(24.w),
            padding: EdgeInsets.all(32.w),
            decoration: BoxDecoration(
              color: const Color(0xFF0A0E21).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(32.r),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(20.w),
                  decoration: BoxDecoration(
                    color: AppColors.goldAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(deed.icon, style: TextStyle(fontSize: 48.sp)),
                ),
                SizedBox(height: 24.h),
                Text(
                  'Barakallah! 🌟',
                  style: TextStyle(
                    color: AppColors.goldAccent,
                    fontWeight: FontWeight.w900,
                    fontSize: 24.sp,
                  ),
                ),
                SizedBox(height: 12.h),
                Text(
                  'Your ${deed.title} has been recorded.\nYou earned +${deed.points} Neki points!',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16.sp,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 32.h),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    setState(() {
                      _selectedDeed = null;
                      _notesController.clear();
                    });
                    context.pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryGreen,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 56.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'MashAllah',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: EdgeInsets.only(left: 12.w),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 20.sp),

            onPressed: () => context.pop(),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Log Good Deed',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Stack(
        children: [
          appBackgroundWidget(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 10.h),
                        _buildSectionTitle('Select Good Deed'),
                        SizedBox(height: 16.h),
                        _buildDeedOptions(),
                        SizedBox(height: 32.h),
                        _buildSectionTitle('Notes (Optional)'),
                        SizedBox(height: 16.h),
                        _buildNotesSection(),
                        SizedBox(height: 40.h),
                      ],
                    ),
                  ),
                ),
                _buildSubmitSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16.sp,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildDeedOptions() {
    return Column(
      children: _deedOptions.map((deed) => _buildDeedOption(deed)).toList(),
    );
  }

  Widget _buildDeedOption(DeedOption deed) {
    final isSelected = _selectedDeed?.id == deed.id;

    return GestureDetector(
      onTap: () => setState(() => _selectedDeed = deed),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryGreen.withValues(alpha: 0.08)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected
                ? AppColors.primaryGreen.withValues(alpha: 0.4)
                : Colors.white.withValues(alpha: 0.08),
            width: 1.5.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52.w,
              height: 52.w,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryGreen.withValues(alpha: 0.15)
                    : Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16.r),
              ),
              child: Center(
                child: Text(deed.icon, style: TextStyle(fontSize: 26.sp)),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    deed.title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6.r),
                    ),
                    child: Text(
                      '+${deed.points} Neki Points',
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppColors.goldAccent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Container(
                width: 24.w,
                height: 24.w,
                decoration: BoxDecoration(
                  color: AppColors.successGreen,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.successGreen.withValues(alpha: 0.3),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(Icons.check, color: Colors.white, size: 14.sp),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Describe your beautiful act of kindness...',
          hintStyle: TextStyle(color: Colors.white24, fontSize: 14.sp),
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(20.w),
        ),
      ),
    );
  }

  Widget _buildSubmitSection() {
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 20.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A).withValues(alpha: 0.8),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.05)),
        ),
      ),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          boxShadow: _selectedDeed != null
              ? [
                  BoxShadow(
                    color: AppColors.primaryGreen.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ]
              : [],
        ),
        child: ElevatedButton(
          onPressed: _selectedDeed != null ? _handleSubmit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryGreen,
            foregroundColor: Colors.white,
            disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
            padding: EdgeInsets.symmetric(vertical: 20.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r),
            ),
            elevation: 0,
          ),
          child: Text(
            'Complete Good Deed',
            style: TextStyle(
              color: _selectedDeed != null ? Colors.white : Colors.white24,
              fontSize: 16.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
}

class DeedOption {
  const DeedOption({
    required this.id,
    required this.title,
    required this.icon,
    required this.points,
  });

  final String id;
  final String title;
  final String icon;
  final int points;
}
