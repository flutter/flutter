// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

void main() {
  // Regression test for https://github.com/flutter/flutter/issues/21506.
  testWidgetsWithLeakTracking('InkSplash receives textDirection', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        appBar: AppBar(title: const Text('Button Border Test')),
        body: Center(
          child: ElevatedButton(
            child: const Text('Test'),
            onPressed: () { },
          ),
        ),
      ),
    ));
    await tester.tap(find.text('Test'));
    // start ink animation which asserts for a textDirection.
    await tester.pumpAndSettle(const Duration(milliseconds: 30));
    expect(tester.takeException(), isNull);
  });

  testWidgetsWithLeakTracking('InkWell with NoSplash splashFactory paints nothing', (WidgetTester tester) async {
    Widget buildFrame({ InteractiveInkFeatureFactory? splashFactory }) {
      return MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Scaffold(
          body: Center(
            child: Material(
              child: InkWell(
                splashFactory: splashFactory,
                onTap: () { },
                child: const Text('test'),
              ),
            ),
          ),
        ),
      );
    }

    // NoSplash.splashFactory, no splash circles drawn
    await tester.pumpWidget(buildFrame(splashFactory: NoSplash.splashFactory));
    {
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('test')));
      final MaterialInkController material = Material.of(tester.element(find.text('test')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(material, paintsExactlyCountTimes(#drawCircle, 0));
      await gesture.up();
      await tester.pumpAndSettle();
    }

    // Default splashFactory (from Theme.of().splashFactory), one splash circle drawn.
    await tester.pumpWidget(buildFrame());
    {
      final TestGesture gesture = await tester.startGesture(tester.getCenter(find.text('test')));
      final MaterialInkController material = Material.of(tester.element(find.text('test')));
      await tester.pump(const Duration(milliseconds: 200));
      expect(material, paintsExactlyCountTimes(#drawCircle, 1));
      await gesture.up();
      await tester.pumpAndSettle();
    }
  });
}
