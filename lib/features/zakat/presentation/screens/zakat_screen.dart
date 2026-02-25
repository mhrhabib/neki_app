import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../cubit/zakat_cubit.dart';
import '../cubit/zakat_state.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../widgets/zakat_breakdown_widget.dart';
import '../../../../components/app_background_widget.dart';

class ZakatScreen extends StatefulWidget {
  const ZakatScreen({super.key});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ZakatCubit>().initCalculator();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Icon(Icons.chevron_left, size: 24.sp, color: Colors.white),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ),
        title: Text(
          "Zakat Calculator",
          style: AppTypography.h1.copyWith(color: AppColors.goldAccent),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          appBackgroundWidget(),
          BlocConsumer<ZakatCubit, ZakatState>(
            listener: (context, state) {
              if (state is ZakatSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: AppColors.successGreen,
                  ),
                );
              } else if (state is ZakatError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            builder: (context, state) {
              if (state is ZakatCalculating) {
                return SingleChildScrollView(
                  padding: EdgeInsets.all(20.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildInfoCard(),
                      SizedBox(height: 20.h),
                      _buildEligibilityBanner(
                        state.isEligible,
                        state.nisabThreshold,
                      ),
                      SizedBox(height: 24.h),
                      _buildInputSection(state),
                      if (state.isEligible) ...[
                        SizedBox(height: 24.h),
                        ZakatBreakdownWidget(
                          totalAssets: state.totalAssets,
                          debts: state.debtsValue,
                          netAssets: state.netAssets,
                          zakatAmount: state.zakatAmount,
                        ),
                        SizedBox(height: 32.h),
                        _buildSubmitButton(state.zakatAmount),
                      ] else ...[
                        SizedBox(height: 24.h),
                        _buildNotEligibleSection(
                          state.netAssets,
                          state.nisabThreshold,
                        ),
                      ],
                      SizedBox(height: 40.h),
                    ],
                  ),
                );
              }
              return const Center(child: CircularProgressIndicator());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.goldAccent, size: 24.sp),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              "Rate of Zakat is 2.5% of your total net assets when it exceeds the Nisab value.",
              style: AppTypography.caption.copyWith(color: AppColors.textDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputSection(ZakatCalculating state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Your Assets", style: AppTypography.h2),
            TextButton.icon(
              onPressed: () => _showNisabSettings(state.nisabThreshold),
              icon: Icon(
                Icons.settings,
                size: 16.sp,
                color: AppColors.primaryGreen,
              ),
              label: Text(
                "Nisab Settings",
                style: TextStyle(
                  fontSize: 12.sp,
                  color: AppColors.primaryGreen,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        _buildTextField(
          label: "Gold & Silver Value",
          initialValue: state.goldValue,
          onChanged: (val) => context.read<ZakatCubit>().updateGold(val),
          icon: Icons.brightness_high,
        ),
        _buildTextField(
          label: "Cash in Hand / Bank",
          initialValue: state.cashValue,
          onChanged: (val) => context.read<ZakatCubit>().updateCash(val),
          icon: Icons.account_balance_wallet,
        ),
        _buildTextField(
          label: "Investments / Stocks",
          initialValue: state.investmentValue,
          onChanged: (val) => context.read<ZakatCubit>().updateInvestment(val),
          icon: Icons.trending_up,
        ),
        _buildTextField(
          label: "Other Assets",
          initialValue: state.otherAssetsValue,
          onChanged: (val) => context.read<ZakatCubit>().updateOtherAssets(val),
          icon: Icons.more_horiz,
        ),
        SizedBox(height: 16.h),
        Text("Deductions", style: AppTypography.h2),
        SizedBox(height: 12.h),
        _buildTextField(
          label: "Debts / Liabilities",
          initialValue: state.debtsValue,
          onChanged: (val) => context.read<ZakatCubit>().updateDebts(val),
          icon: Icons.remove_circle_outline,
          isDebt: true,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required double initialValue,
    required Function(double) onChanged,
    required IconData icon,
    bool isDebt = false,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      child: TextField(
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            color: isDebt ? Colors.red : AppColors.primaryGreen,
          ),
          prefixText: "\$ ",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.r)),
          filled: true,
          fillColor: Colors.white,
        ),
        onChanged: (value) {
          final doubleVal = double.tryParse(value) ?? 0.0;
          onChanged(doubleVal);
        },
      ),
    );
  }

  Widget _buildSubmitButton(double zakatAmount) {
    return ElevatedButton(
      onPressed: zakatAmount > 0
          ? () {
              final authState = context.read<AuthCubit>().state;
              if (authState is Authenticated) {
                context.read<ZakatCubit>().submitZakat(
                  authState.user.id,
                  zakatAmount,
                );
              }
            }
          : null,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryGreen,
        padding: EdgeInsets.symmetric(vertical: 16.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        disabledBackgroundColor: AppColors.dividerGray,
      ),
      child: Text(
        "I have paid my Zakat",
        style: AppTypography.button.copyWith(color: Colors.white),
      ),
    );
  }

  Widget _buildEligibilityBanner(bool isEligible, double threshold) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: isEligible
            ? AppColors.successGreen.withValues(alpha: 0.1)
            : AppColors.textGray.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isEligible
              ? AppColors.successGreen
              : AppColors.textGray.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEligible ? Icons.check_circle : Icons.info_outline,
            color: isEligible ? AppColors.successGreen : AppColors.textGray,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              isEligible
                  ? "You are eligible for Zakat this year! (Net Assets > \$${threshold.toStringAsFixed(0)})"
                  : "You are not eligible for Zakat yet. (Threshold: \$${threshold.toStringAsFixed(0)})",
              style: AppTypography.caption.copyWith(
                color: isEligible ? AppColors.successGreen : AppColors.textGray,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotEligibleSection(double netAssets, double threshold) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.dividerGray),
      ),
      child: Column(
        children: [
          Icon(
            Icons.volunteer_activism_outlined,
            color: AppColors.goldAccent,
            size: 48.sp,
          ),
          SizedBox(height: 16.h),
          Text(
            "Below Nisab Threshold",
            style: AppTypography.h2.copyWith(color: AppColors.textDark),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            "Since your net assets (\$${netAssets.toStringAsFixed(2)}) are below the Nisab threshold (\$${threshold.toStringAsFixed(2)}), Zakat is not mandatory for you. However, you can still give Sadaqah to earn Neki!",
            style: AppTypography.body.copyWith(color: AppColors.textGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showNisabSettings(double currentThreshold) {
    final controller = TextEditingController(text: currentThreshold.toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          20.w,
          20.h,
          20.w,
          MediaQuery.of(context).viewInsets.bottom + 40.h,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Nisab Threshold Setting", style: AppTypography.h2),
            SizedBox(height: 8.h),
            Text(
              "The default is \$1,500 (Silver Nisab). You can update this based on the current market price of 87.48g gold or 612.36g silver.",
              style: AppTypography.caption.copyWith(color: AppColors.textGray),
            ),
            SizedBox(height: 20.h),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Nisab Threshold (USD)",
                prefixIcon: const Icon(Icons.money),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),
            SizedBox(height: 20.h),
            ElevatedButton(
              onPressed: () {
                final newValue = double.tryParse(controller.text) ?? 1500.0;
                this.context.read<ZakatCubit>().updateNisab(newValue);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                minimumSize: Size(double.infinity, 50.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: const Text(
                "Update Threshold",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
