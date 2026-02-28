import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';

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
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                color: AppColors.primaryGreen,
                size: 20.sp,
              ),
              SizedBox(width: 8.w),
              Text(
                "Calculation Summary",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),
          _buildRow(
            "Total Assets",
            totalAssets,
            icon: Icons.add_circle_outline,
            color: Colors.white70,
          ),
          SizedBox(height: 12.h),
          _buildRow(
            "Total Debts",
            debts,
            isSubtracted: true,
            icon: Icons.remove_circle_outline,
            color: Colors.redAccent,
          ),
          SizedBox(height: 16.h),
          Divider(color: Colors.white.withValues(alpha: 0.1), thickness: 1),
          SizedBox(height: 16.h),
          _buildRow("Net Assets", netAssets, isBold: true, color: Colors.white),
          SizedBox(height: 24.h),
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryGreen,
                  AppColors.primaryGreen.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20.r),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryGreen.withValues(alpha: 0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Zakat Due",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      "2.5% of net assets",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
                Text(
                  "\$${zakatAmount.toStringAsFixed(2)}",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRow(
    String label,
    double value, {
    bool isSubtracted = false,
    bool isBold = false,
    IconData? icon,
    required Color color,
  }) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16.sp, color: color.withValues(alpha: 0.5)),
          SizedBox(width: 8.w),
        ],
        Text(
          label,
          style: TextStyle(
            color: isBold ? Colors.white : Colors.white60,
            fontSize: isBold ? 15.sp : 14.sp,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        const Spacer(),
        Text(
          "${isSubtracted ? '-' : ''}\$${value.toStringAsFixed(2)}",
          style: TextStyle(
            color: color,
            fontSize: isBold ? 16.sp : 14.sp,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
