import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/location/cubit/location_cubit.dart';
import '../../../../core/location/cubit/location_state.dart';
import '../cubit/salah_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../points/presentation/cubit/points_cubit.dart';
import '../../../salah_lock/presentation/cubit/salah_lock_cubit.dart';
import '../../../../core/routes/route_names.dart';
import '../../../../components/app_background_widget.dart';
import '../../../../core/widgets/custom_back_button.dart';
import '../../../../core/widgets/custom_icon_button.dart';

class SalahScreen extends StatefulWidget {
  const SalahScreen({super.key});

  @override
  State<SalahScreen> createState() => SalahScreenState();
}

class SalahScreenState extends State<SalahScreen> {
  List<Map<String, String>> get prayers {
    final locationState = context.read<LocationCubit>().state;
    if (locationState is LocationLoaded) {
      final coords = Coordinates(locationState.latitude, locationState.longitude);
      final params = CalculationMethod.karachi.getParameters()..madhab = Madhab.hanafi;
      final pt = PrayerTimes(coords, DateComponents.from(DateTime.now()), params);
      final fmt = DateFormat('h:mm a');
      return [
        {'name': 'Fajr', 'time': fmt.format(pt.fajr)},
        {'name': 'Dhuhr', 'time': fmt.format(pt.dhuhr)},
        {'name': 'Asr', 'time': fmt.format(pt.asr)},
        {'name': 'Maghrib', 'time': fmt.format(pt.maghrib)},
        {'name': 'Isha', 'time': fmt.format(pt.isha)},
      ];
    }
    // Fallback until location loads
    return [
      {'name': 'Fajr', 'time': '--:--'},
      {'name': 'Dhuhr', 'time': '--:--'},
      {'name': 'Asr', 'time': '--:--'},
      {'name': 'Maghrib', 'time': '--:--'},
      {'name': 'Isha', 'time': '--:--'},
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    final authState = context.read<AuthCubit>().state;
    if (authState is Authenticated) {
      context.read<SalahCubit>().loadTodaysSalahs(authState.user.id);
    }
  }

  void _showConfirmationModal(Map<String, String> prayer) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Container(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: EdgeInsets.all(24.w),
              padding: EdgeInsets.all(32.w),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0E21).withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(32.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 30, offset: const Offset(0, 15)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      color: AppColors.primaryGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text('🤲', style: TextStyle(fontSize: 48.sp)),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    'May Allah Accept',
                    style: TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.w900, fontSize: 24.sp),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Your ${prayer['name']} prayer',
                    style: TextStyle(color: Colors.white70, fontSize: 16.sp, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32.h),
                  ElevatedButton(
                    onPressed: () async {
                      final authState = context.read<AuthCubit>().state;
                      if (authState is Authenticated) {
                        final userId = authState.user.id;
                        final salahCubit = context.read<SalahCubit>();
                        final pointsCubit = context.read<PointsCubit>();
                        final salahLockCubit = context.read<SalahLockCubit>();

                        await salahCubit.markSalahComplete(userId: userId, salahName: prayer['name']!);
                        // Cancel notifications + sync local state for this
                        // prayer so the user isn't reminded again today.
                        await salahLockCubit.markPrayerCompletedExternally(prayer['name']!);
                        await pointsCubit.refreshPoints(userId);

                        if (!mounted) return;
                        Navigator.of(context).pop();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      foregroundColor: Colors.white,
                      minimumSize: Size(double.infinity, 56.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Add Neki +25',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16.sp),
                    ),
                  ),
                  SizedBox(height: 12.h),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white38, fontSize: 14.sp),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 70.w,
        leading: CustomBackButton(onPressed: () => context.go('/home')),
        centerTitle: true,
        title: Text(
          "Today's Prayers",
          style: TextStyle(color: Colors.white, fontSize: 20.sp, fontWeight: FontWeight.w800),
        ),
        actions: [
          CustomIconButton(
            icon: Icons.explore_outlined,
            onPressed: () => context.push(RouteNames.qibla),
            baseColor: AppColors.goldAccent,
            size: 44,
            padding: EdgeInsets.only(right: 12.w),
          ),
        ],
      ),
      body: Stack(
        children: [
          appBackgroundWidget(),
          BlocListener<AuthCubit, AuthState>(
            listener: (context, state) {
              if (state is Authenticated) {
                context.read<SalahCubit>().loadTodaysSalahs(state.user.id);
              }
            },
            child: BlocBuilder<AuthCubit, AuthState>(
              builder: (context, authState) {
                if (authState is Authenticated) {
                  return BlocBuilder<SalahCubit, SalahState>(
                    builder: (context, state) {
                      if (state is SalahLoading) {
                        return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
                      }

                      if (state is SalahLoaded) {
                        final completedPrayers = prayers.where((prayer) {
                          return state.salahs.any((salah) => salah.salahName == prayer['name'] && salah.isCompleted);
                        }).length;

                        return SafeArea(
                          child: Column(
                            children: [
                              _buildProgressCard(completedPrayers),
                              Expanded(
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
                                  itemCount: prayers.length,
                                  itemBuilder: (context, index) {
                                    final prayer = prayers[index];
                                    final isCompleted = state.salahs.any(
                                      (salah) => salah.salahName == prayer['name'] && salah.isCompleted,
                                    );
                                    return _buildPrayerCard(prayer, isCompleted);
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (state is SalahError) {
                        return Center(
                          child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.white)),
                        );
                      }

                      return const SizedBox();
                    },
                  );
                }
                return const Center(child: CircularProgressIndicator(color: AppColors.primaryGreen));
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(int completed) {
    final progress = completed / prayers.length;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Prayer Progress',
                style: TextStyle(color: AppColors.goldAccent, fontWeight: FontWeight.w800, fontSize: 16.sp),
              ),
              Text(
                '$completed/${prayers.length}',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18.sp),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Stack(
            children: [
              Container(
                height: 10.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progress,
                child: Container(
                  height: 10.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [AppColors.primaryGreen, Color(0xFF50C878)]),
                    borderRadius: BorderRadius.circular(10.r),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primaryGreen.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Text(
            'Keep going! May Allah accept your prayers 🤲',
            style: TextStyle(color: Colors.white60, fontSize: 13.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildPrayerCard(Map<String, String> prayer, bool isCompleted) {
    return GestureDetector(
      onTap: isCompleted ? null : () => _showConfirmationModal(prayer),
      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: isCompleted ? AppColors.primaryGreen.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24.r),
          border: Border.all(
            color: isCompleted ? AppColors.primaryGreen.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.08),
            width: 1.5.w,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32.w,
              height: 32.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: isCompleted ? AppColors.successGreen : Colors.white24, width: 2),
                color: isCompleted ? AppColors.successGreen : Colors.transparent,
                boxShadow: isCompleted
                    ? [BoxShadow(color: AppColors.successGreen.withValues(alpha: 0.3), blurRadius: 8)]
                    : [],
              ),
              child: isCompleted ? Icon(Icons.check, size: 18.sp, color: Colors.white) : null,
            ),
            SizedBox(width: 20.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayer['name']!,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: isCompleted ? Colors.white60 : Colors.white,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    prayer['time']!,
                    style: TextStyle(color: Colors.white38, fontSize: 14.sp),
                  ),
                ],
              ),
            ),
            if (isCompleted)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: AppColors.goldAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Text('✨', style: TextStyle(fontSize: 10.sp)),
                    SizedBox(width: 4.w),
                    Text(
                      '+25 Neki',
                      style: TextStyle(color: AppColors.goldAccent, fontSize: 12.sp, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
