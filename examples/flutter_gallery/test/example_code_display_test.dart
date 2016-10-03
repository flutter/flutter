// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gallery/gallery/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
  if (binding is LiveTestWidgetsFlutterBinding)
    binding.allowAllFrames = true;

  testWidgets('Flutter gallery button example code displays', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/6147

    await tester.pumpWidget(new GalleryApp());
    await tester.pump(); // see https://github.com/flutter/flutter/issues/1865
    await tester.pump(); // triggers a frame


    // Scroll the Buttons demo into view so that a tap will succeed
    final Point allDemosOrigin = tester.getTopRight(find.text('Demos'));
    final Point buttonsDemoOrigin = tester.getTopRight(find.text('Buttons'));
    final double scrollDelta  = buttonsDemoOrigin.y - allDemosOrigin.y;
    await tester.scrollAt(allDemosOrigin, new Offset(0.0, -scrollDelta));
    await tester.pump(); // start the scroll
    await tester.pump(const Duration(seconds: 1));

    // Launch the buttons demo and then prove that showing the example
    // code dialog does not crash.

    await tester.tap(find.text('Buttons'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1)); // end animation

    await tester.tap(find.text('RAISED'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1)); // end animation

    await tester.tap(find.byTooltip('Show example code'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1)); // end animation

    expect(find.text('Example code'), findsOneWidget);
  });
}
