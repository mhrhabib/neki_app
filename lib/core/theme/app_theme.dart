import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';
import '../constants/app_typography.dart';

/// Central place for app themes
class AppTheme {
  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryGreen,
        secondary: AppColors.goldAccent,
        surface: Colors.white,
        error: Color(0xFFFF3B30),
      ),
      scaffoldBackgroundColor: const Color(0xFFF2F2F7),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        foregroundColor: AppColors.textDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.textDark,
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: const BorderSide(color: Color(0xFFE5E5EA), width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFC6C6C8),
        thickness: 0.5,
        space: 1,
      ),
      textTheme: _buildTextTheme(Brightness.light),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryGreen,
        secondary: AppColors.goldAccent,
        surface: Color(0xFF1C1C1E),
        onSurface: Colors.white,
        error: Color(0xFFFF453A),
      ),
      scaffoldBackgroundColor: Colors.black,
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1C1C1E).withValues(alpha: 0.8),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 17.sp,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1C1C1E),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: const BorderSide(color: Color(0xFF38383A), width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 14.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          elevation: 0,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF38383A),
        thickness: 0.5,
        space: 1,
      ),
      textTheme: _buildTextTheme(Brightness.dark),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1C1C1E),
        selectedItemColor: AppColors.goldAccent,
        unselectedItemColor: Color(0xFF8E8E93),
      ),
    );
  }

  static ThemeData getTheme(Brightness brightness) {
    return brightness == Brightness.dark ? darkTheme() : lightTheme();
  }

  static TextTheme _buildTextTheme(Brightness brightness) {
    final bool isDark = brightness == Brightness.dark;
    final Color textColor = isDark ? Colors.white : AppColors.textDark;
    final Color secondaryTextColor = isDark
        ? const Color(0xFF8E8E93)
        : AppColors.textGray;

    return TextTheme(
      displayLarge: AppTypography.h1.copyWith(color: textColor),
      displayMedium: AppTypography.h2.copyWith(color: textColor),
      displaySmall: AppTypography.h3.copyWith(color: textColor),
      headlineMedium: AppTypography.h2.copyWith(color: textColor),
      headlineSmall: AppTypography.h3.copyWith(color: textColor),
      titleLarge: AppTypography.h3.copyWith(color: textColor),
      bodyLarge: AppTypography.bodyLarge.copyWith(color: textColor),
      bodyMedium: AppTypography.bodyMedium.copyWith(color: textColor),
      bodySmall: AppTypography.bodySmall.copyWith(color: secondaryTextColor),
      labelLarge: AppTypography.labelLarge.copyWith(color: textColor),
      labelMedium: AppTypography.labelMedium.copyWith(
        color: secondaryTextColor,
      ),
    );
  }
}
