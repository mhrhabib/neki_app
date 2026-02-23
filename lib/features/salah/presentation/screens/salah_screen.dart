import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../cubit/salah_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../points/presentation/cubit/points_cubit.dart';
import '../../../../core/routes/route_names.dart';

class SalahScreen extends StatefulWidget {
  const SalahScreen({super.key});

  @override
  State<SalahScreen> createState() => _SalahScreenState();
}

class _SalahScreenState extends State<SalahScreen> {
  final List<Map<String, String>> prayers = [
    {'id': 'fajr', 'name': 'Fajr', 'time': '5:30 AM'},
    {'id': 'dhuha', 'name': 'Dhuha', 'time': '7:00 AM'},
    {'id': 'zuhr', 'name': 'Zuhr', 'time': '1:15 PM'},
    {'id': 'asr', 'name': 'Asr', 'time': '4:45 PM'},
    {'id': 'maghrib', 'name': 'Maghrib', 'time': '6:30 PM'},
    {'id': 'isha', 'name': 'Isha', 'time': '8:00 PM'},
    {'id': 'tahajjud', 'name': 'Tahajjud', 'time': '2:00 AM'},
  ];

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
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🤲', style: TextStyle(fontSize: 48.sp)),
              SizedBox(height: 16.h),
              Text(
                'May Allah Accept',
                style: AppTypography.h2.copyWith(color: AppColors.primaryGreen),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8.h),
              Text(
                'Your ${prayer['name']} prayer',
                style: AppTypography.body.copyWith(color: AppColors.textGray),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24.h),
              ElevatedButton(
                onPressed: () async {
                  final authState = context.read<AuthCubit>().state;
                  if (authState is Authenticated) {
                    final userId = authState.user.id;
                    final salahCubit = context.read<SalahCubit>();
                    final pointsCubit = context.read<PointsCubit>();

                    await salahCubit.markSalahComplete(userId: userId, salahName: prayer['name']!);
                    // Refresh points to update home screen after markSalahComplete finishes
                    await pointsCubit.refreshPoints(userId);

                    if (!mounted) return;
                    Navigator.of(this.context).pop();
                  } else {
                    if (!mounted) return;
                    Navigator.of(this.context).pop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryGreen,
                  padding: EdgeInsets.symmetric(vertical: 14.h, horizontal: 32.w),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                ),
                child: Text('Add Neki +25', style: AppTypography.button.copyWith(color: Colors.white)),
              ),
              SizedBox(height: 10.h),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Cancel', style: AppTypography.body.copyWith(color: AppColors.textGray)),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softCream,
      body: SafeArea(
        child: BlocListener<AuthCubit, AuthState>(
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
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (state is SalahLoaded) {
                      final completedPrayers = prayers.where((prayer) {
                        return state.salahs.any((salah) => salah.salahName == prayer['name'] && salah.isCompleted);
                      }).length;

                      return Column(
                        children: [
                          // Header
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              border: Border(bottom: BorderSide(color: AppColors.dividerGray, width: 1)),
                            ),
                            child: Row(
                              children: [
                                IconButton(
                                  onPressed: () => context.go('/home'),
                                  icon: Icon(Icons.chevron_left, size: 24.sp, color: AppColors.textDark),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.dividerGray,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                  ),
                                ),
                                SizedBox(width: 12.w),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Today's Prayers",
                                        style: AppTypography.h1.copyWith(color: AppColors.primaryGreen),
                                      ),
                                      SizedBox(height: 2.h),
                                      Text(
                                        '$completedPrayers of ${prayers.length} completed',
                                        style: AppTypography.caption.copyWith(color: AppColors.textGray),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => context.push(RouteNames.qibla),
                                  icon: Icon(Icons.explore_outlined, size: 24.sp, color: AppColors.primaryGreen),
                                  style: IconButton.styleFrom(
                                    backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.1),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Progress Card
                          Container(
                            margin: EdgeInsets.all(20.w),
                            padding: EdgeInsets.all(20.w),
                            decoration: BoxDecoration(
                              color: AppColors.primaryGreen,
                              borderRadius: BorderRadius.circular(16.r),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Progress',
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.goldAccent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(height: 8.h),
                                LinearProgressIndicator(
                                  value: completedPrayers / prayers.length,
                                  backgroundColor: Colors.white.withValues(alpha: 0.2),
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.goldAccent),
                                ),
                                SizedBox(height: 12.h),
                                Text(
                                  'Keep going! May Allah accept your prayers 🤲',
                                  style: AppTypography.caption.copyWith(color: Colors.white),
                                ),
                              ],
                            ),
                          ),

                          // Prayers List
                          Expanded(
                            child: ListView.builder(
                              padding: EdgeInsets.symmetric(horizontal: 20.w),
                              itemCount: prayers.length,
                              itemBuilder: (context, index) {
                                final prayer = prayers[index];
                                final isCompleted = state.salahs.any(
                                  (salah) => salah.salahName == prayer['name'] && salah.isCompleted,
                                );

                                return GestureDetector(
                                  onTap: isCompleted ? null : () => _showConfirmationModal(prayer),
                                  child: Container(
                                    margin: EdgeInsets.only(bottom: 12.h),
                                    padding: EdgeInsets.all(18.w),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(14.r),
                                      border: Border.all(
                                        color: isCompleted ? AppColors.primaryGreen : AppColors.dividerGray,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 28.w,
                                          height: 28.w,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: isCompleted ? AppColors.primaryGreen : AppColors.dividerGray,
                                              width: 2,
                                            ),
                                            color: isCompleted ? AppColors.primaryGreen : Colors.white,
                                          ),
                                          child: isCompleted
                                              ? Icon(Icons.check, size: 16.sp, color: Colors.white)
                                              : null,
                                        ),
                                        SizedBox(width: 16.w),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                prayer['name']!,
                                                style: AppTypography.body.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: isCompleted ? AppColors.textGray : AppColors.textDark,
                                                  decoration: isCompleted ? TextDecoration.lineThrough : null,
                                                ),
                                              ),
                                              SizedBox(height: 2.h),
                                              Text(
                                                prayer['time']!,
                                                style: AppTypography.caption.copyWith(color: AppColors.textGray),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (isCompleted)
                                          Container(
                                            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                                            decoration: BoxDecoration(
                                              color: AppColors.goldAccent.withValues(alpha: 0.2),
                                              borderRadius: BorderRadius.circular(6.r),
                                            ),
                                            child: Text(
                                              '+25 Neki',
                                              style: AppTypography.caption.copyWith(
                                                color: AppColors.goldAccent,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }

                    if (state is SalahError) {
                      return Center(child: Text('Error: ${state.message}'));
                    }

                    return const SizedBox();
                  },
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ),
      ),
    );
  }
}
