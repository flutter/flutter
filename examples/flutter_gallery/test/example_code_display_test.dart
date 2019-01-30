// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gallery/gallery/app.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
  if (binding is LiveTestWidgetsFlutterBinding)
    binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  testWidgets('Flutter gallery button example code displays', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/6147

    await tester.pumpWidget(const GalleryApp(testMode: true));
    await tester.pump(); // see https://github.com/flutter/flutter/issues/1865
    await tester.pump(); // triggers a frame

    await Scrollable.ensureVisible(tester.element(find.text('Material')), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Material'));
    await tester.pumpAndSettle();

    // Launch the buttons demo and then prove that showing the example
    // code dialog does not crash.

    await tester.tap(find.text('Buttons'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Show example code'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(seconds: 1)); // end animation

    expect(find.text('Example code'), findsOneWidget);
  });
}
