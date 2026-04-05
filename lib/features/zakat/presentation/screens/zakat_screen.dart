import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_back_button.dart';
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 70.w,
        leading: const CustomBackButton(),
        centerTitle: true,
        title: Text(
          "Zakat Calculator",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
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
                return SafeArea(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 10.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildInfoCard(),
                        SizedBox(height: 24.h),
                        _buildEligibilityBanner(
                          state.isEligible,
                          state.nisabThreshold,
                        ),
                        SizedBox(height: 32.h),
                        _buildInputSection(state),
                        if (state.isEligible) ...[
                          SizedBox(height: 32.h),
                          ZakatBreakdownWidget(
                            totalAssets: state.totalAssets,
                            debts: state.debtsValue,
                            netAssets: state.netAssets,
                            zakatAmount: state.zakatAmount,
                          ),
                          SizedBox(height: 32.h),
                          _buildSubmitButton(state.zakatAmount),
                        ] else ...[
                          SizedBox(height: 32.h),
                          _buildNotEligibleSection(
                            state.netAssets,
                            state.nisabThreshold,
                          ),
                        ],
                        SizedBox(height: 60.h),
                      ],
                    ),
                  ),
                );
              }
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primaryGreen),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: AppColors.goldAccent.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: AppColors.goldAccent.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.info_outline,
              color: AppColors.goldAccent,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Text(
              "Rate of Zakat is 2.5% of your total net assets when it exceeds the Nisab value.",
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13.sp,
                height: 1.4,
              ),
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
            Text(
              "Your Assets",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
            GestureDetector(
              onTap: () => _showNisabSettings(state.nisabThreshold),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.settings,
                      size: 14.sp,
                      color: AppColors.goldAccent,
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      "Nisab Settings",
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20.h),
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
        SizedBox(height: 24.h),
        Text(
          "Deductions",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 16.h),
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
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: TextField(
        keyboardType: TextInputType.number,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white54, fontSize: 13.sp),
          prefixIcon: Icon(
            icon,
            color: isDebt ? Colors.redAccent : AppColors.primaryGreen,
            size: 20.sp,
          ),
          prefixText: "\$ ",
          prefixStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 12.h,
          ),
        ),
        onChanged: (value) {
          final doubleVal = double.tryParse(value) ?? 0.0;
          onChanged(doubleVal);
        },
      ),
    );
  }

  Widget _buildSubmitButton(double zakatAmount) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: zakatAmount > 0
            ? [
                BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ]
            : [],
      ),
      child: ElevatedButton(
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
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 20.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.r),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.white.withValues(alpha: 0.1),
        ),
        child: Text(
          "I have paid my Zakat",
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildEligibilityBanner(bool isEligible, double threshold) {
    final statusColor = isEligible ? AppColors.successGreen : Colors.white60;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: isEligible
            ? AppColors.successGreen.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(
          color: isEligible
              ? AppColors.successGreen.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isEligible ? Icons.check_circle : Icons.error_outline,
            color: statusColor,
            size: 22.sp,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              isEligible
                  ? "You are eligible for Zakat this year! (Net Assets > \$${threshold.toStringAsFixed(0)})"
                  : "Net assets are currently below the Nisab mandatory threshold of \$${threshold.toStringAsFixed(0)}",
              style: TextStyle(
                color: statusColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotEligibleSection(double netAssets, double threshold) {
    return Container(
      padding: EdgeInsets.all(32.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppColors.goldAccent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.volunteer_activism_outlined,
              color: AppColors.goldAccent,
              size: 40.sp,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            "Below Nisab Threshold",
            style: TextStyle(
              color: Colors.white,
              fontSize: 20.sp,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 12.h),
          Text(
            "Since your net assets (\$${netAssets.toStringAsFixed(2)}) are below the Nisab threshold (\$${threshold.toStringAsFixed(2)}), Zakat is not mandatory for you.",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 14.sp,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24.h),
          Text(
            "However, you can still give Sadaqah to earn Neki!",
            style: TextStyle(
              color: AppColors.goldAccent,
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
            ),
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
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.fromLTRB(
          24.w,
          20.h,
          24.w,
          MediaQuery.of(context).viewInsets.bottom + 40.h,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFF0A0E21).withValues(alpha: 0.98),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              "Nisab Threshold Setting",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              "The default is \$1,500 (Silver Nisab). You can update this based on current market rates.",
              style: TextStyle(
                color: Colors.white54,
                fontSize: 13.sp,
                height: 1.4,
              ),
            ),
            SizedBox(height: 24.h),
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                decoration: InputDecoration(
                  labelText: "Nisab Threshold (USD)",
                  labelStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(
                    Icons.attach_money,
                    color: AppColors.goldAccent,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                ),
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: () {
                final newValue = double.tryParse(controller.text) ?? 1500.0;
                this.context.read<ZakatCubit>().updateNisab(newValue);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 56.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                elevation: 0,
              ),
              child: const Text(
                "Update Threshold",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
