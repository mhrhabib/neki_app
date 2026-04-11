import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget appBackgroundWidget() {
  return Stack(
    children: [
      // 1. Background Gradient
      Positioned.fill(
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0D2818), Color(0xFF07150C)],
            ),
          ),
        ),
      ),

      // 2. Islamic Pattern Overlay
      Positioned.fill(child: CustomPaint(painter: _IslamicPatternPainter())),

      // 3. Faded Mosque Asset
      Positioned(
        top: 20.h,
        left: 0,
        right: 0,
        child: Opacity(
          opacity: 0.1,
          child: Image.asset(
            'assets/Mosque-01 1.png',
            fit: BoxFit.fitWidth,
            width: 1.sw,
          ),
        ),
      ),
    ],
  );
}

/// Custom painter for Islamic geometric background pattern
class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // Draw subtle star pattern
    const double spacing = 60;
    for (double x = 0; x < size.width + spacing; x += spacing) {
      for (double y = 0; y < size.height + spacing; y += spacing) {
        _drawStar(canvas, Offset(x, y), 20, paint);
      }
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (3.14159265 / 180);
      final r = i % 2 == 0 ? radius : radius * 0.45;
      final x = center.dx + r * (angle == 0 ? 1 : _cos(angle));
      final y = center.dy + r * _sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  double _cos(double angle) {
    return angle == 0 ? 1.0 : (1.0 - angle * angle / 2);
  }

  double _sin(double angle) {
    return angle - angle * angle * angle / 6;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
