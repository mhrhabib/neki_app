import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget appBackgroundWidget() {
  return Positioned.fill(
    child: Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.2,
          colors: [Color(0xFF202020), Color(0xFF000000)],
        ),
      ),
      child: Stack(
        children: [
          // 1. Background Gradient/Texture effect
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [Color(0xFF202020), Color(0xFF000000)],
                ),
              ),
            ),
          ),

          // 2. Faded Mosque Asset at the top (Sketch style)
          Positioned(
            top: 10.h,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/Mosque-01 1.png',
                fit: BoxFit.fitWidth,
                width: 1.sw,
              ),
            ),
          ),

          // 3. Side Decorations (Mandalas)
        ],
      ),
    ),
  );
}
