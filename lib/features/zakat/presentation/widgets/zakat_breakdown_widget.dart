import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';

class ZakatBreakdownWidget extends StatelessWidget {
  final double totalAssets;
  final double debts;
  final double netAssets;
  final double zakatAmount;

  const ZakatBreakdownWidget({
    super.key,
    required this.totalAssets,
    required this.debts,
    required this.netAssets,
    required this.zakatAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppColors.dividerGray),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Calculation Summary", style: AppTypography.h2.copyWith(color: AppColors.primaryGreen)),
          SizedBox(height: 16.h),
          _buildRow("Total Assets", totalAssets),
          _buildRow("Total Debts", debts, isSubtracted: true),
          const Divider(),
          _buildRow("Net Assets", netAssets, isBold: true),
          SizedBox(height: 20.h),
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(color: AppColors.primaryGreen, borderRadius: BorderRadius.circular(12.r)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Zakat (2.5%)",
                  style: AppTypography.body.copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                Text(
                  "\$${zakatAmount.toStringAsFixed(2)}",
                  style: AppTypography.body.copyWith(
                    color: AppColors.goldAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, double value, {bool isSubtracted = false, bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.body.copyWith(
              color: AppColors.textGray,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            "${isSubtracted ? '-' : ''}\$${value.toStringAsFixed(2)}",
            style: AppTypography.body.copyWith(
              color: isSubtracted ? Colors.red : AppColors.textDark,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
