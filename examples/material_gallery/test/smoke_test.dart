// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_gallery/gallery/app.dart' as material_gallery_app;
import 'package:material_gallery/gallery/item.dart' as material_gallery_item;
import 'package:material_gallery/main.dart' as material_gallery_main;
import 'package:test/test.dart';

// Warning: the following strings must be kept in sync with GalleryHome.
const List<String> demoCategories = const <String>['Demos', 'Components', 'Style'];

Finder findGalleryItemByRouteName(WidgetTester tester, String routeName) {
  return find.byWidgetPredicate((Widget widget) {
    return widget is material_gallery_item.GalleryItem
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
void smokeDemo(WidgetTester tester, String routeName) {
  // Ensure that we're (likely to be) on the home page
  final Finder menuItem = findGalleryItemByRouteName(tester, routeName);
  expect(menuItem, findsOneWidget);

  tester.tap(menuItem);
  tester.pump(); // Launch the demo.
  tester.pump(const Duration(seconds: 1)); // Wait until the demo has opened.

  // Go back
  Finder backButton = findBackButton(tester);
  expect(backButton, findsOneWidget);
  tester.tap(backButton);
  tester.pump(); // Start the navigator pop "back" operation.
  tester.pump(const Duration(seconds: 1)); // Wait until it has finished.
}

void main() {
  testWidgets('Material Gallery app smoke test', (WidgetTester tester) {
    material_gallery_main.main(); // builds the app and schedules a frame but doesn't trigger one
    tester.pump(); // see https://github.com/flutter/flutter/issues/1865
    tester.pump(); // triggers a frame

    // Expand the demo category submenus.
    for (String category in demoCategories.reversed) {
      tester.tap(find.text(category));
      tester.pump();
      tester.pump(const Duration(seconds: 1)); // Wait until the menu has expanded.
    }

    final List<double> scrollDeltas = new List<double>();
    double previousY = tester.getTopRight(find.text(demoCategories[0])).y;
    final List<String> routeNames = material_gallery_app.kRoutes.keys.toList();
    for (String routeName in routeNames) {
      final double y = tester.getTopRight(findGalleryItemByRouteName(tester, routeName)).y;
      scrollDeltas.add(previousY - y);
      previousY = y;
    }

    // Launch each demo and then scroll that item out of the way.
    for (int i = 0; i < routeNames.length; i += 1) {
      final String routeName = routeNames[i];
      smokeDemo(tester, routeName);
      tester.scroll(findGalleryItemByRouteName(tester, routeName), new Offset(0.0, scrollDeltas[i]));
      tester.pump();
    }

    Finder navigationMenuButton = findNavigationMenuButton(tester);
    expect(navigationMenuButton, findsOneWidget);
    tester.tap(navigationMenuButton);
    tester.pump(); // Start opening drawer.
    tester.pump(const Duration(seconds: 1)); // Wait until it's really opened.

    // switch theme
    tester.tap(find.text('Dark'));
    tester.pump();
    tester.pump(const Duration(seconds: 1)); // Wait until it's changed.

    // switch theme
    tester.tap(find.text('Light'));
    tester.pump();
    tester.pump(const Duration(seconds: 1)); // Wait until it's changed.
  });
}
