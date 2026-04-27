import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/constants/app_colors.dart';

class CelebrationOverlay extends StatefulWidget {
  final String title;
  final String subtitle;
  final String points;
  final VoidCallback onClaim;

  const CelebrationOverlay({
    super.key,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.onClaim,
  });

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = List.generate(50, (index) => _Particle());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      body: Stack(
        children: [
          // Animated Particles (Confetti)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: _ConfettiPainter(_particles, _controller.value),
                size: Size.infinite,
              );
            },
          ),
          
          // Content
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 40.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIcon(),
                  SizedBox(height: 32.h),
                  _buildTextContent(),
                  SizedBox(height: 48.h),
                  _buildClaimButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIcon() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            padding: EdgeInsets.all(30.w),
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.goldAccent.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.star_rounded,
              color: AppColors.goldAccent,
              size: 80.sp,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextContent() {
    return Column(
      children: [
        Text(
          widget.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.sanchez(
            color: Colors.white,
            fontSize: 28.sp,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 12.h),
        Text(
          widget.subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16.sp,
            height: 1.4,
          ),
        ),
        SizedBox(height: 24.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '+${widget.points}',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 24.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'NEKI',
                style: TextStyle(
                  color: AppColors.primaryGreen,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildClaimButton() {
    return SizedBox(
      width: double.infinity,
      height: 60.h,
      child: ElevatedButton(
        onPressed: widget.onClaim,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          elevation: 0,
        ),
        child: Text(
          'ALHAMDULILLAH',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }
}

class _Particle {
  late double x, y, speed, size;
  late Color color;
  late double angle;

  _Particle() {
    _reset();
  }

  void _reset() {
    x = Random().nextDouble();
    y = -0.1;
    speed = 0.5 + Random().nextDouble() * 2;
    size = 4 + Random().nextDouble() * 8;
    angle = Random().nextDouble() * pi * 2;
    color = [
      AppColors.primaryGreen,
      AppColors.goldAccent,
      Colors.white,
      Colors.blueAccent,
    ][Random().nextInt(4)];
  }

  void update(double value) {
    y += speed * 0.01;
    x += sin(y * 4) * 0.002;
    if (y > 1.1) _reset();
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _ConfettiPainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    for (var particle in particles) {
      particle.update(animationValue);
      final paint = Paint()..color = particle.color;
      final pos = Offset(particle.x * size.width, particle.y * size.height);
      
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(particle.angle + animationValue * 10);
      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size / 2),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
