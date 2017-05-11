// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gallery/main.dart' as flutter_gallery_main;

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
  if (binding is LiveTestWidgetsFlutterBinding)
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Flutter Gallery app simple smoke test', (WidgetTester tester) async {
    flutter_gallery_main.main(); // builds the app and schedules a frame but doesn't trigger one
    await tester.pump(); // see https://github.com/flutter/flutter/issues/1865
    await tester.pump(); // triggers a frame

    final Finder finder = find.byWidgetPredicate((Widget widget) {
      return widget is Tooltip && widget.message == 'Open navigation menu';
    });
    expect(finder, findsOneWidget);

    // Open drawer
    await tester.tap(finder);
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1)); // end animation

    // Change theme
    await tester.tap(find.text('Dark'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1)); // end animation

    // Close drawer
    await tester.tap(find.byType(DrawerController));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1)); // end animation

    // Open Demos
    await tester.tap(find.text('Demos'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1)); // end animation

    // Open Flexible space toolbar
    await tester.tap(find.text('Contact profile'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1)); // end animation

    // Scroll it up
    await tester.drag(find.text('(650) 555-1234'), const Offset(0.0, -50.0));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.drag(find.text('(650) 555-1234'), const Offset(0.0, -50.0));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.drag(find.text('(650) 555-1234'), const Offset(0.0, -50.0));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.drag(find.text('(650) 555-1234'), const Offset(0.0, -50.0));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.drag(find.text('(650) 555-1234'), const Offset(0.0, -50.0));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.drag(find.text('(650) 555-1234'), const Offset(0.0, -50.0));
    await tester.pump(const Duration(milliseconds: 200));

    await tester.pump(const Duration(hours: 100)); // for testing
  });
}
