import 'package:flutter/material.dart';

/// Small placeholder wrapper similar to the React Native `KeyboardAvoidingAnimatedView`.
class KeyboardAvoidingAnimatedView extends StatelessWidget {
  final Widget child;
  const KeyboardAvoidingAnimatedView({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(child: SafeArea(child: child));
  }
}
