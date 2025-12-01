import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/di/set_up_di.dart';
import 'core/routes/app_router.dart';
import 'core/constants/app_colors.dart';
import 'features/theme/theme_cubit.dart';
import 'features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/salah/presentation/cubit/salah_cubit.dart';
import 'features/points/presentation/cubit/points_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SetUpDI.init();
  runApp(const NekiApp());
}

class NekiApp extends StatelessWidget {
  const NekiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => getIt<ThemeCubit>()..loadTheme()),
        BlocProvider(create: (context) => getIt<OnboardingCubit>()..checkOnboarding()),
        BlocProvider(create: (context) => getIt<AuthCubit>()..checkAuthStatus()),
        BlocProvider(create: (context) => getIt<SalahCubit>()),
        BlocProvider(create: (context) => getIt<PointsCubit>()),
      ],
      child: Builder(
        builder: (context) {
          return BlocBuilder<ThemeCubit, ThemeState>(
            builder: (context, state) {
              bool isDark = false;
              if (state is ThemeLoaded) {
                isDark = state.isDarkMode;
              }
              return ScreenUtilInit(
                designSize: const Size(375, 812),
                minTextAdapt: true,
                splitScreenMode: true,
                builder: (context, child) {
                  return MaterialApp.router(
                    title: 'Neki Tracker',
                    theme: _buildLightTheme(),
                    darkTheme: _buildDarkTheme(),
                    themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
                    routerConfig: AppRouter.router(context),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
        secondary: AppColors.goldAccent,
        surface: AppColors.softCream,
      ),
      scaffoldBackgroundColor: AppColors.softCream,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardWhite,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.cardWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.dividerGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.dividerGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
      ),
      dividerColor: AppColors.dividerGray,
    );
  }

  static ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primaryGreen,
        primary: AppColors.primaryGreen,
        secondary: AppColors.goldAccent,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: AppColors.darkGreen,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        color: AppColors.textDark,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGreen,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.textDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.dividerGray),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.dividerGray),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide(color: AppColors.primaryGreen, width: 2),
        ),
      ),
      dividerColor: AppColors.dividerGray,
    );
  }
}
