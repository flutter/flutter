// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

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
      // Force rotation
      await moreReliableSetOrentations(tester, DeviceOrientation.portraitUp);
      // Load app widget.
      await tester.pumpWidget(const MyApp());
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
      await moreReliableSetOrentations(tester, DeviceOrientation.landscapeLeft);
      // Load app widget.
      await tester.pumpWidget(const MyApp());
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
      await moreReliableSetOrentations(tester, DeviceOrientation.portraitUp);
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
      await moreReliableSetOrentations(tester, DeviceOrientation.landscapeLeft);
      await tester.pumpWidget(widgetUnderTest);

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

/*
 * Force rotation then poll to ensure rotation has happened.
 *
 * Rotations have an async communication to engine which then has an async
 * communication to the android operating system.
 */
Future<void> moreReliableSetOrentations(
  WidgetTester tester,
  DeviceOrientation orientation,
) async {
  SystemChrome.setPreferredOrientations([orientation]);
  Orientation expectedOrientation;
  switch (orientation) {
    case DeviceOrientation.portraitUp:
    case DeviceOrientation.portraitDown:
      expectedOrientation = Orientation.portrait;
      break;
    case DeviceOrientation.landscapeRight:
    case DeviceOrientation.landscapeLeft:
      expectedOrientation = Orientation.landscape;
      break;
  }
  do {
    BuildContext context = tester.element(find.byType(Text));
    if (expectedOrientation == MediaQuery.of(context).orientation) {
      break;
    }
    await tester.pumpAndSettle();
  } while (true);
}

List<DisplayFeature> getCutouts(WidgetTester tester, BuildContext context) {
  List<DisplayFeature> displayFeatures = MediaQuery.of(context).displayFeatures;
  displayFeatures.retainWhere(
    (DisplayFeature feature) => feature.type == DisplayFeatureType.cutout,
  );
  return displayFeatures;
}
