// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gallery/gallery/app.dart' as flutter_gallery_app;
import 'package:flutter_gallery/gallery/item.dart' as flutter_gallery_item;
import 'package:flutter_gallery/main.dart' as flutter_gallery_main;

// Warning: the following strings must be kept in sync with GalleryHome.
const List<String> demoCategories = const <String>['Demos', 'Components', 'Style'];

Finder findGalleryItemByRouteName(WidgetTester tester, String routeName) {
  return find.byWidgetPredicate((Widget widget) {
    return widget is flutter_gallery_item.GalleryItem
        && widget.routeName == routeName;
  });
}

Finder byTooltip(WidgetTester tester, String message) {
  return find.byWidgetPredicate((Widget widget) {
    return widget is Tooltip && widget.message == message;
  });
}

Finder findNavigationMenuButton(WidgetTester tester) => byTooltip(tester, 'Open navigation menu');

Finder findBackButton(WidgetTester tester) => byTooltip(tester, 'Back');

// Start a gallery demo and then go back. This function assumes that the
// we're starting on home route and that the submenu that contains the demo
// called 'name' is already open.
Future<Null> smokeDemo(WidgetTester tester, String routeName) async {
  // Ensure that we're (likely to be) on the home page
  final Finder menuItem = findGalleryItemByRouteName(tester, routeName);
  expect(menuItem, findsOneWidget);

  await tester.tap(menuItem);
  await tester.pump(); // Launch the demo.
  await tester.pump(const Duration(seconds: 1)); // Wait until the demo has opened.

  // Go back
  Finder backButton = findBackButton(tester);
  expect(backButton, findsOneWidget);
  await tester.tap(backButton);
  await tester.pump(); // Start the navigator pop "back" operation.
  await tester.pump(const Duration(seconds: 1)); // Wait until it has finished.
  return null;
}

void main() {
  TestWidgetsFlutterBinding binding = TestWidgetsFlutterBinding.ensureInitialized();
  if (binding is LiveTestWidgetsFlutterBinding)
    binding.allowAllFrames = true;

  testWidgets('Flutter Gallery app smoke test', (WidgetTester tester) async {
    flutter_gallery_main.main(); // builds the app and schedules a frame but doesn't trigger one
    await tester.pump(); // see https://github.com/flutter/flutter/issues/1865
    await tester.pump(); // triggers a frame

    // Expand the demo category submenus.
    for (String category in demoCategories.reversed) {
      await tester.tap(find.text(category));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1)); // Wait until the menu has expanded.
    }

    final List<double> scrollDeltas = new List<double>();
    double previousY = tester.getTopRight(find.text(demoCategories[0])).y;
    final List<String> routeNames = flutter_gallery_app.kRoutes.keys.toList();
    for (String routeName in routeNames) {
      final double y = tester.getTopRight(findGalleryItemByRouteName(tester, routeName)).y;
      scrollDeltas.add(previousY - y);
      previousY = y;
    }

    // Launch each demo and then scroll that item out of the way.
    for (int i = 0; i < routeNames.length; i += 1) {
      final String routeName = routeNames[i];
      await smokeDemo(tester, routeName);
      await tester.scroll(findGalleryItemByRouteName(tester, routeName), new Offset(0.0, scrollDeltas[i]));
      await tester.pump();
    }

    Finder navigationMenuButton = findNavigationMenuButton(tester);
    expect(navigationMenuButton, findsOneWidget);
    await tester.tap(navigationMenuButton);
    await tester.pump(); // Start opening drawer.
    await tester.pump(const Duration(seconds: 1)); // Wait until it's really opened.

    // switch theme
    await tester.tap(find.text('Dark'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Wait until it's changed.

    // switch theme
    await tester.tap(find.text('Light'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // Wait until it's changed.
  }, skip: true);
}
