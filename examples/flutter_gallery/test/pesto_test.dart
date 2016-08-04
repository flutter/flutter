// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gallery/main.dart' as flutter_gallery_main;

Finder byTooltip(WidgetTester tester, String message) {
  return find.byWidgetPredicate((Widget widget) {
    return widget is Tooltip && widget.message == message;
  });
}

Finder findNavigationMenuButton(WidgetTester tester) {
  return byTooltip(tester, 'Open navigation menu');
}

void main() {
  TestWidgetsFlutterBinding binding =
      TestWidgetsFlutterBinding.ensureInitialized();
  if (binding is LiveTestWidgetsFlutterBinding) binding.allowAllFrames = true;

  // Regression test for https://github.com/flutter/flutter/pull/5168
  testWidgets('Pesto route management', (WidgetTester tester) async {
    flutter_gallery_main
        .main(); // builds the app and schedules a frame but doesn't trigger one
    await tester.pump(); // see https://github.com/flutter/flutter/issues/1865
    await tester.pump(); // triggers a frame

    expect(find.text('Pesto'), findsOneWidget);
    await tester.tap(find.text('Pesto'));
    await tester.pump(); // Launch pesto
    await tester.pump(const Duration(seconds: 1)); // transition is complete

    Future<Null> tapDrawerItem(String title) async {
      await tester.tap(findNavigationMenuButton(tester));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // drawer opening animation
      await tester.tap(find.text(title));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // drawer closing animation
      await tester.pump(); // maybe open a new page
      return tester.pump(const Duration(seconds: 1)); // new page transition
    }
    await tapDrawerItem('Home');
    await tapDrawerItem('Favorites');
    await tapDrawerItem('Home');
    await tapDrawerItem('Favorites');
    await tapDrawerItem('Home');
    await tapDrawerItem('Return to Gallery');

    expect(find.text('Flutter Gallery'), findsOneWidget);
  });
}
