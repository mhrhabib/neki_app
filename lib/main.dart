import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/di/set_up_di.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/theme/theme_cubit.dart';
import 'features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/salah/presentation/cubit/salah_cubit.dart';
import 'features/points/presentation/cubit/points_cubit.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase before setting up DI so repositories can rely on Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await SetUpDI.init();
  runApp(const NekiApp());
}

class NekiApp extends StatefulWidget {
  const NekiApp({super.key});

  @override
  State<NekiApp> createState() => _NekiAppState();
}

class _NekiAppState extends State<NekiApp> {
  @override
  void initState() {
    super.initState();
    // Router will be initialized after BLoC providers are available
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ThemeCubit>()),
        BlocProvider(create: (context) => getIt<OnboardingCubit>()..checkOnboarding()),
        BlocProvider(create: (context) => getIt<AuthCubit>()..checkAuthStatus()),
        BlocProvider(create: (context) => getIt<SalahCubit>()),
        BlocProvider(create: (context) => getIt<PointsCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeData>(
        builder: (context, themeData) {
          debugPrint('🎨 Theme changed to: ${themeData.brightness}');
          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MaterialApp.router(
                title: 'Neki Tracker',
                theme: AppTheme.lightTheme(),
                darkTheme: AppTheme.darkTheme(),
                themeMode: themeData.brightness == Brightness.dark ? ThemeMode.dark : ThemeMode.light,
                routerConfig: AppRouter.router,
                debugShowCheckedModeBanner: false,
              );
            },
          );
        },
      ),
    );
  }
}
