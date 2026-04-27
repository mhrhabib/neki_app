import 'package:flutter/material.dart';

/// Donation-mode pass-through. Premium features are now unlocked for all
/// users; this widget is kept so existing call sites keep compiling while
/// the rest of the paywall UI is removed.
class PremiumLockedGuard extends StatelessWidget {
  final Widget child;
  final String title;

  const PremiumLockedGuard({
    super.key,
    required this.child,
    this.title = 'Premium Insights',
  });

  @override
  Widget build(BuildContext context) => child;
}
