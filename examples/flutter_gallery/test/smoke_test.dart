// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show LinkedHashSet;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_gallery/gallery/item.dart' show GalleryItem, kAllGalleryItems;
import 'package:flutter_gallery/gallery/app.dart' show GalleryApp;

const String kCaption = 'Flutter Gallery';

final List<String> demoCategories = new LinkedHashSet<String>.from(
  kAllGalleryItems.map<String>((GalleryItem item) => item.category)
).toList();

final List<String> routeNames =
  kAllGalleryItems.map((GalleryItem item) => item.routeName).toList();

Finder findGalleryItemByRouteName(WidgetTester tester, String routeName) {
  return find.byWidgetPredicate((Widget widget) {
    return widget is GalleryItem && widget.routeName == routeName;
  });
}

int errors = 0;

void reportToStringError(String name, String route, int lineNumber, List<String> lines, String message) {
  // If you're on line 12, then it has index 11.
  // If you want 1 line before and 1 line after, then you want lines with index 10, 11, and 12.
  // That's (lineNumber-1)-margin .. (lineNumber-1)+margin, or lineNumber-(margin+1) .. lineNumber+(margin-1)
  const int margin = 5;
  final int firstLine = math.max(0, lineNumber - margin);
  final int lastLine = math.min(lines.length, lineNumber + margin);
  print('$name : $route : line $lineNumber of ${lines.length} : $message; nearby lines were:\n  ${lines.sublist(firstLine, lastLine).join("\n  ")}');
  errors += 1;
}

void verifyToStringOutput(String name, String route, String testString) {
  int lineNumber = 0;
  final List<String> lines = testString.split('\n');
  if (!testString.endsWith('\n'))
    reportToStringError(name, route, lines.length, lines, 'does not end with a line feed');
  for (String line in lines) {
    lineNumber += 1;
    if (line == '' && lineNumber != lines.length) {
      reportToStringError(name, route, lineNumber, lines, 'found empty line');
    } else if (line.contains('Instance of ')) {
      reportToStringError(name, route, lineNumber, lines, 'found a class that does not have its own toString');
    } else if (line.endsWith(' ')) {
      reportToStringError(name, route, lineNumber, lines, 'found a line with trailing whitespace');
    }
  }
}

// Start a gallery demo and then go back. This function assumes that the
// we're starting on the home route and that the submenu that contains
// the item for a demo that pushes route 'routeName' is already open.
Future<Null> smokeDemo(WidgetTester tester, String routeName) async {
  // Ensure that we're (likely to be) on the home page
  final Finder menuItem = findGalleryItemByRouteName(tester, routeName);
  expect(menuItem, findsOneWidget);

  // Don't use pumpUntilNoTransientCallbacks in this function, because some of
  // the smoketests have infinitely-running animations (e.g. the progress
  // indicators demo).

  await tester.tap(menuItem);
  await tester.pump(); // Launch the demo.
  await tester.pump(const Duration(milliseconds: 400)); // Wait until the demo has opened.
  expect(find.text(kCaption), findsNothing);

  // Leave the demo on the screen briefly for manual testing.
  await tester.pump(const Duration(milliseconds: 400));

  // Scroll the demo around a bit.
  await tester.flingFrom(const Offset(400.0, 300.0), const Offset(-100.0, 0.0), 500.0);
  await tester.flingFrom(const Offset(400.0, 300.0), const Offset(0.0, -100.0), 500.0);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 400));

  // Verify that the dumps are pretty.
  verifyToStringOutput('debugDumpApp', routeName, WidgetsBinding.instance.renderViewElement.toStringDeep());
  verifyToStringOutput('debugDumpRenderTree', routeName, RendererBinding.instance?.renderView?.toStringDeep());
  verifyToStringOutput('debugDumpLayerTree', routeName, RendererBinding.instance?.renderView?.debugLayer?.toStringDeep());

  // Scroll the demo around a bit more.
  await tester.flingFrom(const Offset(400.0, 300.0), const Offset(-200.0, 0.0), 500.0);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 50));
  await tester.pump(const Duration(milliseconds: 200));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.flingFrom(const Offset(400.0, 300.0), const Offset(100.0, 0.0), 500.0);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
  await tester.flingFrom(const Offset(400.0, 300.0), const Offset(0.0, 400.0), 1000.0);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));

  // Go back
  final Finder backButton = find.byTooltip('Back');
  expect(backButton, findsOneWidget);
  await tester.tap(backButton);
  await tester.pump(); // Start the pop "back" operation.
  await tester.pump(); // Complete the willPop() Future.
  await tester.pump(const Duration(milliseconds: 400)); // Wait until it has finished.
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

  for (String routeName in routeNames) {
    final Finder finder = findGalleryItemByRouteName(tester, routeName);
    Scrollable.ensureVisible(tester.element(finder), alignment: 0.5);
    await tester.pumpAndSettle();
    await smokeDemo(tester, routeName);
    tester.binding.debugAssertNoTransientCallbacks('A transient callback was still active after leaving route $routeName');
  }
  expect(errors, 0);

  final Finder navigationMenuButton = find.byTooltip('Open navigation menu');
  expect(navigationMenuButton, findsOneWidget);
  await tester.tap(navigationMenuButton);
  await tester.pump(); // Start opening drawer.
  await tester.pump(const Duration(seconds: 1)); // Wait until it's really opened.

  // Switch theme.
  await tester.tap(find.text('Dark'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1)); // Wait until it's changed.

  // Switch theme.
  await tester.tap(find.text('Light'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1)); // Wait until it's changed.

  // Switch font scale.
  await tester.tap(find.text('Small'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1)); // Wait until it's changed.
  // Switch font scale back to default.
  await tester.tap(find.text('System Default'));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1)); // Wait until it's changed.

  // Scroll the 'Send feedback' item into view.
  await tester.drag(find.text('Small'), const Offset(0.0, -1000.0));
  await tester.pump();
  await tester.pump(const Duration(seconds: 1)); // Wait until it's changed.

  // Send feedback.
  expect(hasFeedback, false);
  await tester.tap(find.text('Send feedback'));
  await tester.pump();
  expect(hasFeedback, true);
}

void main() {
  testWidgets('Flutter Gallery app smoke test', runSmokeTest);

  testWidgets('Flutter Gallery app smoke test with semantics', (WidgetTester tester) async {
    RendererBinding.instance.setSemanticsEnabled(true);
    await runSmokeTest(tester);
    RendererBinding.instance.setSemanticsEnabled(false);
  });
}
