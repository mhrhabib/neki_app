import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:neki_app/main.dart';
import 'package:neki_app/core/di/set_up_di.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await SetUpDI.init();
    await ScreenUtil.ensureScreenSize();
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    // Set test screen size
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1.0;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const NekiApp());

    // Verify that the splash screen appears
    expect(find.text('NEKI TRACKER'), findsOneWidget);

    // Allow timers to finish by advancing time
    await tester.pumpAndSettle(const Duration(seconds: 5));

    // After navigation, app should still be running
    expect(find.byType(NekiApp), findsOneWidget);

    // Reset screen size
    addTearDown(tester.view.reset);
  });
}
