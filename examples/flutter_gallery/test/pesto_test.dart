// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gallery/gallery/app.dart';

void main() {
  TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
  if (binding is LiveTestWidgetsFlutterBinding)
    binding.allowAllFrames = true;

  // Regression test for https://github.com/flutter/flutter/pull/5168
  testWidgets('Pesto appbar heroics', (WidgetTester tester) async {
    await tester.pumpWidget(
      // The bug only manifests itself when the screen's orientation is portrait
      new Center(
        child: new SizedBox(
          width: 400.0,
          height: 800.0,
          child: new GalleryApp()
        )
      )
    );
    await tester.pump(); // see https://github.com/flutter/flutter/issues/1865
    await tester.pump(); // triggers a frame

    await tester.tap(find.text('Pesto'));
    await tester.pump(); // Launch pesto
    await tester.pump(const Duration(seconds: 1)); // transition is complete

    await tester.tap(find.text('Pesto Bruchetta'));
    await tester.pump(); // Launch the recipe page
    await tester.pump(const Duration(seconds: 1)); // transition is complete

    await tester.scroll(find.text('Pesto Bruchetta'), const Offset(0.0, -300.0));
    await tester.pump();

    Navigator.pop(find.byType(Scaffold).evaluate().single);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // transition is complete
  });
}
