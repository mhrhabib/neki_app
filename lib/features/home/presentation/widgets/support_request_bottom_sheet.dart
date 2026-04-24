import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/iap_service.dart';

class SupportRequestBottomSheet extends StatefulWidget {
  final String title;
  final String message;
  final Future<void> Function(String productId) onDonate;
  final VoidCallback onMaybeLater;
  final VoidCallback onUnable;
  final IAPService iapService;

  const SupportRequestBottomSheet({
    super.key,
    required this.title,
    required this.message,
    required this.onDonate,
    required this.onMaybeLater,
    required this.onUnable,
    required this.iapService,
  });

  @override
  State<SupportRequestBottomSheet> createState() =>
      _SupportRequestBottomSheetState();
}

class _SupportRequestBottomSheetState extends State<SupportRequestBottomSheet> {
  String _selectedProductId = IAPService.support5Id;
  bool _busy = false;

  Future<void> _handleDonate() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await widget.onDonate(_selectedProductId);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(24.w, 12.h, 24.w, 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E).withValues(alpha: 0.95),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.only(bottom: 20.h),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: AppColors.goldAccent.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.favorite_rounded,
                color: AppColors.goldAccent,
                size: 32.sp,
              ),
            ),
            SizedBox(height: 20.h),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14.sp,
                height: 1.5,
              ),
            ),
            SizedBox(height: 24.h),
            _buildServerGoalBar(),
            SizedBox(height: 24.h),
            _AmountPicker(
              products: widget.iapService.donationProducts,
              selectedId: _selectedProductId,
              onChanged: (id) => setState(() => _selectedProductId = id),
            ),
            SizedBox(height: 20.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _busy ? null : _handleDonate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldAccent,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor:
                      AppColors.goldAccent.withValues(alpha: 0.4),
                  padding: EdgeInsets.symmetric(vertical: 16.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  elevation: 0,
                ),
                child: _busy
                    ? SizedBox(
                        height: 18.h,
                        width: 18.h,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : Text(
                        'Support (Sadaqah)',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: _busy ? null : widget.onMaybeLater,
              child: Text(
                'Maybe later',
                style: TextStyle(
                  color: Colors.white38,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            TextButton(
              onPressed: _busy ? null : widget.onUnable,
              child: Text(
                'I am unable to donate',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 13.sp,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServerGoalBar() {
    const double current = 120;
    const double goal = 300;
    const double progress = current / goal;

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Server Goal',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '\$${current.toInt()} / \$${goal.toInt()} raised',
                style: TextStyle(
                  color: AppColors.goldAccent,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Stack(
            children: [
              Container(
                height: 8.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(4.r),
                ),
              ),
              LayoutBuilder(
                builder: (context, constraints) {
                  return Container(
                    height: 8.h,
                    width: constraints.maxWidth * progress,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.goldAccent, Color(0xFFFFD700)],
                      ),
                      borderRadius: BorderRadius.circular(4.r),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.goldAccent.withValues(alpha: 0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            'Help us reach the goal to keep Neki running this month!',
            style: TextStyle(
              color: Colors.white38,
              fontSize: 11.sp,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountPicker extends StatelessWidget {
  final List<ProductDetails> products;
  final String selectedId;
  final ValueChanged<String> onChanged;

  const _AmountPicker({
    required this.products,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final tiles = _tiles();
    return Wrap(
      spacing: 10.w,
      runSpacing: 10.h,
      alignment: WrapAlignment.center,
      children: tiles.map((t) {
        final selected = t.id == selectedId;
        return GestureDetector(
          onTap: () => onChanged(t.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            constraints: BoxConstraints(minWidth: 72.w),
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.goldAccent.withValues(alpha: 0.18)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(
                color: selected
                    ? AppColors.goldAccent
                    : Colors.white.withValues(alpha: 0.08),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: Text(
                t.label,
                style: TextStyle(
                  color: selected ? AppColors.goldAccent : Colors.white70,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<_Tile> _tiles() {
    // Prefer store-localized prices when available, otherwise fall back to
    // fixed labels so the UI degrades gracefully on devices without IAP.
    ProductDetails? find(String id) {
      for (final p in products) {
        if (p.id == id) return p;
      }
      return null;
    }

    final p1 = find(IAPService.support1Id);
    final p5 = find(IAPService.support5Id);
    final p10 = find(IAPService.support10Id);
    final p20 = find(IAPService.support20Id);

    return [
      _Tile(IAPService.support1Id, p1?.price ?? r'$1'),
      _Tile(IAPService.support5Id, p5?.price ?? r'$5'),
      _Tile(IAPService.support10Id, p10?.price ?? r'$10'),
      _Tile(IAPService.support20Id, p20?.price ?? r'$20'),
    ];
  }
}

class _Tile {
  final String id;
  final String label;
  const _Tile(this.id, this.label);
}
