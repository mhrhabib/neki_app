import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

class AddictionCounterWidget extends StatefulWidget {
  final DateTime startDate;

  const AddictionCounterWidget({super.key, required this.startDate});

  @override
  State<AddictionCounterWidget> createState() => _AddictionCounterWidgetState();
}

class _AddictionCounterWidgetState extends State<AddictionCounterWidget> {
  late Timer _timer;
  late Duration _elapsed;

  @override
  void initState() {
    super.initState();
    _elapsed = DateTime.now().difference(widget.startDate);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _elapsed = DateTime.now().difference(widget.startDate);
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _elapsed.inDays;
    final hours = _elapsed.inHours % 24;
    final minutes = _elapsed.inMinutes % 60;
    final seconds = _elapsed.inSeconds % 60;

    return Container(
      padding: EdgeInsets.symmetric(vertical: 24.h),
      width: double.infinity,
      child: Column(
        children: [
          Text(
            'TIME SINCE START',
            style: TextStyle(
              color: AppColors.goldAccent.withValues(alpha: 0.7),
              fontSize: 12.sp,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildTimeUnit(days.toString().padLeft(2, '0'), 'DAYS'),
              _buildSeparator(),
              _buildTimeUnit(hours.toString().padLeft(2, '0'), 'HOURS'),
              _buildSeparator(),
              _buildTimeUnit(minutes.toString().padLeft(2, '0'), 'MINS'),
              _buildSeparator(),
              _buildTimeUnit(seconds.toString().padLeft(2, '0'), 'SECS'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeUnit(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 32.sp,
            fontWeight: FontWeight.w900,
            fontFamily: 'Monospace',
            letterSpacing: 1.2,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          label,
          style: TextStyle(
            color: Colors.white38,
            fontSize: 9.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildSeparator() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10.w),
      child: Text(
        ':',
        style: TextStyle(
          color: AppColors.goldAccent.withValues(alpha: 0.3),
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
