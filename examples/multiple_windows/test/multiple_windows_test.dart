// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multiple_windows/main.dart' as multiple_windows;
import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;

void main() {
  isWindowingEnabled = true;

  testWidgets('Multiple windows smoke test', (WidgetTester tester) async {
    multiple_windows
        .main(); // builds the app and schedules a frame but doesn't trigger one
    await tester.pump(); // triggers a frame

    expect(
      find.widgetWithText(AppBar, 'Multi Window Reference App'),
      findsOneWidget,
    );
  });

  testWidgets('Can create a regular window', (WidgetTester tester) async {
    multiple_windows
        .main(); // builds the app and schedules a frame but doesn't trigger one
    await tester.pump(); // triggers a frame

    final toTap = find.widgetWithText(OutlinedButton, 'Regular');
    expect(toTap, findsOneWidget);
    await tester.tap(toTap);
    await tester.pump();

    expect(find.widgetWithText(AppBar, 'Regular Window'), findsOneWidget);
  });

  testWidgets('Can create a modal dialog of a regular window', (
    WidgetTester tester,
  ) async {
    multiple_windows
        .main(); // builds the app and schedules a frame but doesn't trigger one
    await tester.pump(); // triggers a frame

    final toTap = find.widgetWithText(OutlinedButton, 'Regular');
    expect(toTap, findsOneWidget);
    await tester.tap(toTap);
    await tester.pump();

    final createModalButton = find.widgetWithText(
      ElevatedButton,
      'Create Modal Dialog',
    );
    expect(createModalButton, findsOneWidget);
    await tester.tap(createModalButton);
    await tester.pump();

    expect(find.widgetWithText(AppBar, 'Dialog'), findsOneWidget);
  });
}
