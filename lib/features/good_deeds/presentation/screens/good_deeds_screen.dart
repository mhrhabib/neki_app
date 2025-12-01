import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';

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
    DeedOption(id: 'dhikr', title: 'Dhikr', icon: '📿', points: 20),
    DeedOption(id: 'volunteer', title: 'Volunteer', icon: '🤝', points: 60),
    DeedOption(id: 'kindness', title: 'Act of Kindness', icon: '💚', points: 25),
  ];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    if (_selectedDeed == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a good deed')));
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Barakallah! 🌟'),
        content: Text('Your ${_selectedDeed!.title} has been recorded.\n+${_selectedDeed!.points} Neki points'),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
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
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937)),
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
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(color: const Color(0xFFF3F4F6), borderRadius: BorderRadius.circular(10.r)),
              child: const Icon(Icons.chevron_left, color: Color(0xFF1F2937)),
            ),
          ),
          SizedBox(width: 12.w),
          Text(
            'Log Good Deed',
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.w700, color: AppColors.primaryGreen),
          ),
        ],
      ),
    );
  }

  Widget _buildDeedOptions() {
    return Column(children: _deedOptions.map((deed) => _buildDeedOption(deed)).toList());
  }

  Widget _buildDeedOption(DeedOption deed) {
    final isSelected = _selectedDeed?.id == deed.id;

    return GestureDetector(
      onTap: () => setState(() => _selectedDeed = deed),
      child: Container(
        margin: EdgeInsets.only(bottom: 10.h),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(color: isSelected ? AppColors.primaryGreen : const Color(0xFFE5E7EB), width: 2.w),
        ),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryGreen.withValues(alpha: 0.15) : const Color(0xFFF9FAFB),
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
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937)),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes (Optional)',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: const Color(0xFF1F2937)),
        ),
        SizedBox(height: 12.h),
        TextField(
          controller: _notesController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Add any details about your good deed...',
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
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
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
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
