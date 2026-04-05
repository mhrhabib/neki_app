import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class CustomIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Color baseColor;
  final double size;
  final EdgeInsets? padding;

  const CustomIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.baseColor = Colors.white,
    this.size = 40,
    this.padding,
  });

  @override
  State<CustomIconButton> createState() => _CustomIconButtonState();
}

class _CustomIconButtonState extends State<CustomIconButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onPressed();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 10.0),
              child: Container(
                width: widget.size.w,
                height: widget.size.w,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: widget.baseColor.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.baseColor.withValues(alpha: 0.1), width: 0.5),
                ),
                child: Icon(widget.icon, color: widget.baseColor, size: (widget.size * 0.55).sp),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
