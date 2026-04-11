import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/di/set_up_di.dart';
import 'core/routes/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/theme/theme_cubit.dart';
import 'features/beat_satan_chalange/presentation/cubit/onboarding_cubit.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/salah/presentation/cubit/salah_cubit.dart';
import 'features/points/presentation/cubit/points_cubit.dart';
import 'features/challenge/presentation/cubit/challenge_cubit.dart';
import 'core/location/cubit/location_cubit.dart';
import 'features/salah_lock/presentation/cubit/salah_lock_cubit.dart';
import 'features/salah_lock/presentation/widgets/salah_lock_overlay.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<ThemeCubit>()),
        BlocProvider.value(value: getIt<OnboardingCubit>()..checkOnboarding()),
        BlocProvider.value(value: getIt<AuthCubit>()..checkAuthStatus()),
        BlocProvider.value(value: getIt<SalahCubit>()),
        BlocProvider.value(value: getIt<PointsCubit>()),
        BlocProvider.value(value: getIt<ChallengeCubit>()),
        BlocProvider.value(value: getIt<LocationCubit>()..fetchLocation()),
        BlocProvider.value(value: getIt<SalahLockCubit>()..init()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeData>(
        builder: (context, themeData) {
          return ScreenUtilInit(
            designSize: const Size(375, 812),
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (context, child) {
              return MaterialApp.router(
                title: 'Neki Tracker',
                theme: AppTheme.lightTheme(),
                darkTheme: AppTheme.darkTheme(),
                themeMode: themeData.brightness == Brightness.dark
                    ? ThemeMode.dark
                    : ThemeMode.light,
                routerConfig: AppRouter.router,
                debugShowCheckedModeBanner: false,
                builder: (context, child) {
                  return Stack(
                    children: [
                      ?child,
                      const SalahLockOverlay(),
                    ],
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
