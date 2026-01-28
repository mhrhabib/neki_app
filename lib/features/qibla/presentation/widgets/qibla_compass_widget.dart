import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_qiblah/flutter_qiblah.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

class QiblaCompassWidget extends StatelessWidget {
  const QiblaCompassWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FlutterQiblah.qiblahStream,
      builder: (context, AsyncSnapshot<QiblahDirection> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final qiblahDirection = snapshot.data!;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "${qiblahDirection.direction.toInt()}°",
              style: AppTypography.h1.copyWith(
                color: AppColors.primaryGreen,
                fontSize: 40.sp,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              "Align the needle with the Kaaba icon",
              style: AppTypography.caption.copyWith(color: AppColors.textGray),
            ),
            SizedBox(height: 40.h),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Compass Circle and Marks
                  CustomPaint(
                    size: Size(300.w, 300.w),
                    painter: CompassPainter(),
                  ),
                  // Compass Needle (Device Heading)
                  Transform.rotate(
                    angle: (qiblahDirection.direction * (math.pi / 180) * -1),
                    child: CustomPaint(
                      size: Size(300.w, 300.w),
                      painter: QiblaNeedlePainter(),
                    ),
                  ),
                  // Qibla Indicator (Kaaba)
                  Transform.rotate(
                    angle: (qiblahDirection.qiblah * (math.pi / 180) * -1),
                    child: Container(
                      alignment: Alignment.topCenter,
                      height: 300.w,
                      width: 300.w,
                      child: Padding(
                        padding: EdgeInsets.only(top: 10.w),
                        child: Icon(
                          Icons.mosque,
                          color: AppColors.goldAccent,
                          size: 32.sp,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final circlePaint = Paint()
      ..color = AppColors.primaryGreen.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = AppColors.primaryGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.w;

    canvas.drawCircle(center, radius, circlePaint);
    canvas.drawCircle(center, radius, borderPaint);

    // Draw cardinal directions
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    const directions = ['N', 'E', 'S', 'W'];
    for (var i = 0; i < directions.length; i++) {
      final angle = i * math.pi / 2 - math.pi / 2;
      final x = center.dx + (radius - 20) * math.cos(angle);
      final y = center.dy + (radius - 20) * math.sin(angle);

      textPainter.text = TextSpan(
        text: directions[i],
        style: TextStyle(
          color: AppColors.primaryGreen,
          fontSize: 16.sp,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Draw degree marks
    final markPaint = Paint()
      ..color = AppColors.primaryGreen.withOpacity(0.5)
      ..strokeWidth = 1.w;

    for (var i = 0; i < 360; i += 5) {
      final angle = i * math.pi / 180;
      final isMajor = i % 30 == 0;
      final length = isMajor ? 12.w : 6.w;

      final startX = center.dx + (radius - 2.w) * math.cos(angle);
      final startY = center.dy + (radius - 2.w) * math.sin(angle);
      final endX = center.dx + (radius - length) * math.cos(angle);
      final endY = center.dy + (radius - length) * math.sin(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), markPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class QiblaNeedlePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final paint = Paint()
      ..color = AppColors.primaryGreen
      ..style = PaintingStyle.fill;

    // Draw the north part of the needle (red-ish or highlighted)
    final northPath = Path()
      ..moveTo(center.dx, center.dy - radius + 20.w)
      ..lineTo(center.dx - 8.w, center.dy)
      ..lineTo(center.dx + 8.w, center.dy)
      ..close();

    canvas.drawPath(northPath, paint..color = Colors.red);

    // Draw the south part of the needle (dark green)
    final southPath = Path()
      ..moveTo(center.dx, center.dy + radius - 20.w)
      ..lineTo(center.dx - 8.w, center.dy)
      ..lineTo(center.dx + 8.w, center.dy)
      ..close();

    canvas.drawPath(southPath, paint..color = AppColors.primaryGreen);

    // Draw a small circle in the center
    canvas.drawCircle(center, 4.w, Paint()..color = AppColors.goldAccent);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
