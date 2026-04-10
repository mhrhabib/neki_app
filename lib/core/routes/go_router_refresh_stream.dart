import 'dart:async';
import 'package:flutter/material.dart';

/// A [Listenable] that notifies when ANY of the provided [streams] emit a value.
/// Used to refresh [GoRouter] when BLoC/Cubit states change.
class GoRouterRefreshStream extends ChangeNotifier {
  late final List<StreamSubscription<dynamic>> _subscriptions;

  GoRouterRefreshStream(List<Stream<dynamic>> streams) {
    _subscriptions = [];
    
    // Trigger initial notification so GoRouter checks state immediately on startup
    // or when the router is recreated.
    notifyListeners();

    for (final stream in streams) {
      final subscription = stream.asBroadcastStream().listen(
            (dynamic _) => notifyListeners(),
          );
      _subscriptions.add(subscription);
    }
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }
}
