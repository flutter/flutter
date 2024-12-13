import 'dart:ui';

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
      BuildContext context = tester.element(find.byType(Text));
      List<DisplayFeature> displayFeatures = getCutouts(tester, context);
      // Test is expecting one cutout setup in the test harness.
      expect(
        displayFeatures.length,
        1,
        reason: 'Single cutout display feature expected',
      );
      // Verify that app code thinks there is a top cutout.
      expect(
        displayFeatures[0].bounds.top,
        0,
        reason:
            'cutout should start at the top, does the test device have a '
            'camera cutout or window inset?',
      );
    });

    testWidgets('cutout should be on left in landscape left', (tester) async {
      // Load app widget.
      await tester.pumpWidget(const MyApp());
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
      ]);
      await tester.pumpAndSettle();
      BuildContext context = tester.element(find.byType(Text));
      // Verify that app code thinks there is a left cutout.
      List<DisplayFeature> displayFeatures = getCutouts(tester, context);
      // Test is expecting one cutout setup in the test harness.
      expect(
        displayFeatures.length,
        1,
        reason: 'Single cutout display feature expected',
      );
      expect(
        displayFeatures[0].bounds.left,
        0,
        reason:
            'cutout should start at the left, does the test device have a '
            'camera cutout or window inset?',
      );
    });

    testWidgets('cutout handles rotation', (tester) async {
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.portraitUp,
      ]);
      const widgetUnderTest = MyApp();
      // Load app widget.
      await tester.pumpWidget(widgetUnderTest);
      BuildContext context = tester.element(find.byType(Text));
      List<DisplayFeature> displayFeatures = getCutouts(tester, context);

      // Test is expecting one cutout setup in the test harness.
      expect(
        displayFeatures.length,
        1,
        reason: 'Single cutout display feature expected',
      );
      // Verify that app code thinks there is a top cutout.
      expect(
        displayFeatures[0].bounds.top,
        0,
        reason:
            'cutout should start at the top, does the test device have a '
            'camera cutout or window inset?',
      );
      SystemChrome.setPreferredOrientations(<DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
      ]);
      await tester.pumpWidget(widgetUnderTest);
      await tester.pumpAndSettle(Durations.extralong4);

      // Requery for display features after rotation.
      context = tester.element(find.byType(Text));
      displayFeatures = getCutouts(tester, context);
      // Test is expecting one cutout setup in the test harness.
      expect(
        displayFeatures.length,
        1,
        reason: 'Single cutout display feature expected',
      );
      expect(
        displayFeatures[0].bounds.left,
        0,
        reason: 'cutout should start at the left or handle camera',
      );
    });

    tearDown(() {
      // After each test reset to device perfered orientations to avoid
      // test pollution.
      SystemChrome.setPreferredOrientations([]);
    });
  });
}

List<DisplayFeature> getCutouts(WidgetTester tester, BuildContext context) {
  List<DisplayFeature> displayFeatures = MediaQuery.of(context).displayFeatures;
  displayFeatures.retainWhere(
    (DisplayFeature feature) => feature.type == DisplayFeatureType.cutout,
  );
  return displayFeatures;
}
