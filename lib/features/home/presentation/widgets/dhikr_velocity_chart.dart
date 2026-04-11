import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

class DhikrVelocityChart extends StatelessWidget {
  final Map<String, int> dailyCounts;

  const DhikrVelocityChart({super.key, required this.dailyCounts});

  @override
  Widget build(BuildContext context) {
    // Process data: get last 7 days sorted
    final now = DateTime.now();
    final List<int> values = [];
    final List<String> labels = [];

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().split('T')[0];
      values.add(dailyCounts[dateStr] ?? 0);
      labels.add(_getDayLabel(date));
    }

    final maxVal = values.isNotEmpty ? values.reduce(max).toDouble() : 100.0;
    final displayMax = maxVal == 0 ? 100.0 : maxVal * 1.2;

    return Container(
      height: 200.h,
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 10.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Expanded(
            child: CustomPaint(
              painter: _LineChartPainter(values, displayMax),
              size: Size.infinite,
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: labels
                .map(
                  (l) => Text(
                    l,
                    style: TextStyle(
                      color: Colors.white24,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  String _getDayLabel(DateTime date) {
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday - 1];
  }
}

class _LineChartPainter extends CustomPainter {
  final List<int> values;
  final double maxValue;

  _LineChartPainter(this.values, this.maxValue);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final paint = Paint()
      ..color = AppColors.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.primaryGreen.withValues(alpha: 0.3),
          AppColors.primaryGreen.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    final double dx = size.width / (values.length - 1);

    for (int i = 0; i < values.length; i++) {
      final double x = i * dx;
      final double y = size.height - (values[i] / maxValue * size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        // Smooth curve using Bezier
        final prevX = (i - 1) * dx;
        final prevY = size.height - (values[i - 1] / maxValue * size.height);
        final controlX = prevX + (x - prevX) / 2;
        path.cubicTo(controlX, prevY, controlX, y, x, y);
        fillPath.cubicTo(controlX, prevY, controlX, y, x, y);
      }

      if (i == values.length - 1) {
        fillPath.lineTo(x, size.height);
        fillPath.close();
      }
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    // Draw data points
    final dotPaint = Paint()..color = Colors.white;
    final dotOuterPaint = Paint()..color = AppColors.primaryGreen;

    for (int i = 0; i < values.length; i++) {
      final double x = i * dx;
      final double y = size.height - (values[i] / maxValue * size.height);
      canvas.drawCircle(Offset(x, y), 5.r, dotOuterPaint);
      canvas.drawCircle(Offset(x, y), 3.r, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
