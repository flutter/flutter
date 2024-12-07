import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:display_cutout_rotation/main.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    // Test assumes a custom driver that enables
    // "com.android.internal.display.cutout.emulation.tall".
    testWidgets('cutout should be on top in portrait mode', (tester) async {
      // Load app widget.
      await tester.pumpWidget(const MyApp());
      // Force rotation
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.portraitUp,
      ]);
      await tester.pumpAndSettle();
      // Verify that app code thinks there is a top cutout.
      expect(find.byKey(const ValueKey('CutoutTop')), findsOneWidget);
    });

    testWidgets('cutout should be on left in landscape left', (tester) async {
      // Load app widget.
      await tester.pumpWidget(const MyApp());
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
      ]);
      await tester.pumpAndSettle();
      // Verify that app code thinks there is a left cutout.
      expect(find.byKey(const ValueKey('CutoutLeft')), findsOneWidget);
    });

    testWidgets('cutout handles rotation', (tester) async {
      // TODO try to query mediaquery directly without checking widgets. 
      // Load app widget.
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.portraitUp,
      ]);
      await tester.pumpWidget(const MyApp());
      // Verify that app code thinks there is a top cutout.
      expect(find.byKey(const ValueKey('CutoutTop')), findsOneWidget);
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
      ]);
      await tester.pumpAndSettle();
      // Verify that app code thinks there is a left cutout.
      expect(find.byKey(const ValueKey('CutoutLeft')), findsOneWidget);
    });

    tearDown(() {
      // After each test reset to device perfered orientations to avoid
      // test pollution.
      SystemChrome.setPreferredOrientations([]);
    });

    // test('cutout should update on screen rotation', () async {
    //   await nativeDriver.rotateResetDefault();
    //   await flutterDriver.waitFor(find.byValueKey('CutoutTop'),
    //       timeout: const Duration(seconds: 5));
    //   await nativeDriver.rotateToLandscape();
    //   await flutterDriver.waitFor(find.byValueKey('CutoutLeft'),
    //       timeout: const Duration(seconds: 5));
    // }, timeout: Timeout.none);
  });
}
