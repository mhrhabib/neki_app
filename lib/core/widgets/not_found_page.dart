import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';
import '../constants/app_typography.dart';
import '../routes/route_names.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0E27) : AppColors.softCream,
      appBar: AppBar(title: const Text('Page Not Found'), backgroundColor: isDark ? const Color(0xFF1F2937) : null),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.outerPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 80.sp, color: Colors.red),
              SizedBox(height: 16.h),
              Text('404', style: AppTypography.h1.copyWith(fontSize: 48.sp)),
              SizedBox(height: 8.h),
              Text('Page not found', style: AppTypography.body),
              SizedBox(height: 32.h),
              ElevatedButton(
                onPressed: () => context.go(RouteNames.home),
                child: Text('Go Home', style: AppTypography.button),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
