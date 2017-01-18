// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show LinkedHashSet;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gallery/gallery/item.dart' show GalleryItem, kAllGalleryItems;
import 'package:flutter_gallery/gallery/app.dart' show GalleryApp;

const String kCaption = 'Flutter Gallery';

final List<String> demoCategories = new LinkedHashSet<String>.from(
  kAllGalleryItems.map((GalleryItem item) => item.category)
).toList();

final List<String> routeNames =
  kAllGalleryItems.map((GalleryItem item) => item.routeName).toList();

Finder findGalleryItemByRouteName(WidgetTester tester, String routeName) {
  return find.byWidgetPredicate((Widget widget) {
    return widget is GalleryItem && widget.routeName == routeName;
  });
}

// Start a gallery demo and then go back. This function assumes that the
// we're starting on the home route and that the submenu that contains
// the item for a demo that pushes route 'routeName' is already open.
Future<Null> smokeDemo(WidgetTester tester, String routeName) async {
  // Ensure that we're (likely to be) on the home page
  final Finder menuItem = findGalleryItemByRouteName(tester, routeName);
  expect(menuItem, findsOneWidget);

  await tester.tap(menuItem);
  await tester.pump(); // Launch the demo.
  await tester.pump(const Duration(seconds: 1)); // Wait until the demo has opened.

  expect(find.text(kCaption), findsNothing);

  // Go back
  Finder backButton = find.byTooltip('Back');
  expect(backButton, findsOneWidget);
  await tester.tap(backButton);
  await tester.pump(); // Start the pop "back" operation.
  await tester.pump(); // Complete the willPop() Future.
  await tester.pump(const Duration(seconds: 1)); // Wait until it has finished.
  return null;
}

Future<Null> runSmokeTest(WidgetTester tester) async {
  bool hasFeedback = false;
  void mockOnSendFeedback() {
    hasFeedback = true;
  }

  await tester.pumpWidget(new GalleryApp(onSendFeedback: mockOnSendFeedback));
  await tester.pump(); // see https://github.com/flutter/flutter/issues/1865
  await tester.pump(); // triggers a frame

  expect(find.text(kCaption), findsOneWidget);

  final List<double> scrollDeltas = new List<double>();
  double previousY = tester.getTopRight(find.text(demoCategories[0])).y;
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
    await tester.pump(); // start the scroll
    await tester.pump(const Duration(milliseconds: 500)); // wait for overscroll to timeout, if necessary
    await tester.pump(const Duration(seconds: 3)); // wait for overscroll to fade away, if necessary
    tester.binding.debugAssertNoTransientCallbacks('A transient callback was still active after leaving route $routeName');
  }

  Finder navigationMenuButton = find.byTooltip('Open navigation menu');
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

  // send feedback
  expect(hasFeedback, false);
  await tester.tap(find.text('Send feedback'));
  await tester.pump();
  expect(hasFeedback, true);
}

void main() {
  testWidgets('Flutter Gallery app smoke test', runSmokeTest);

  testWidgets('Flutter Gallery app smoke test', (WidgetTester tester) async {
    RendererBinding.instance.setSemanticsEnabled(true);
    await runSmokeTest(tester);
    RendererBinding.instance.setSemanticsEnabled(false);
  });
}
