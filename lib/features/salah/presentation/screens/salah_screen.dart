import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/constants/app_spacing.dart';
import '../cubit/salah_cubit.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';

class SalahScreen extends StatelessWidget {
  const SalahScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.softCream,
      appBar: AppBar(title: const Text('Salah Tracker')),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          if (authState is Authenticated) {
            context.read<SalahCubit>().loadTodaysSalahs(authState.user.id);

            return BlocBuilder<SalahCubit, SalahState>(
              builder: (context, state) {
                if (state is SalahLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is SalahLoaded) {
                  return ListView.builder(
                    padding: EdgeInsets.all(AppSpacing.outerPadding),
                    itemCount: state.salahs.length,
                    itemBuilder: (context, index) {
                      final salah = state.salahs[index];
                      return Card(
                        margin: EdgeInsets.only(bottom: AppSpacing.gridGap),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.cornerRadius)),
                        child: ListTile(
                          leading: Icon(
                            salah.isCompleted ? Icons.check_circle : Icons.circle_outlined,
                            color: salah.isCompleted ? AppColors.successGreen : AppColors.textGray,
                            size: 32.sp,
                          ),
                          title: Text(salah.salahName, style: AppTypography.body.copyWith(fontWeight: FontWeight.w600)),
                          subtitle: Text(
                            salah.isCompleted ? 'Completed +${salah.pointsEarned} points' : 'Mark as done',
                          ),
                          trailing: !salah.isCompleted
                              ? ElevatedButton(
                                  onPressed: () {
                                    context.read<SalahCubit>().markSalahComplete(
                                      userId: authState.user.id,
                                      salahName: salah.salahName,
                                    );
                                  },
                                  child: const Text('Done'),
                                )
                              : null,
                        ),
                      );
                    },
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
    );
  }
}
