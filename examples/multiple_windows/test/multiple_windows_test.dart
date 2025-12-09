// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
// ignore: avoid_relative_lib_imports
import '../lib/main.dart' as multiple_windows;
import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;

void main() {
  if (!isWindowingEnabled) {
    const String windowingDisabledErrorMessage = '''
Skipping multiple_windows_test.dart because Windowing APIs are not enabled.

Windowing APIs are currently experimental. Do not use windowing APIs in
production applications or plugins published to pub.dev.

To try experimental windowing APIs:
1. Switch to Flutter's main release channel.
2. Turn on the windowing feature flag.

See: https://github.com/flutter/flutter/issues/30701.
''';
    testWidgets(windowingDisabledErrorMessage, (WidgetTester tester) async {
      // No-op test to avoid "no tests found" error.
    });
    return;
  }

  testWidgets('Multiple windows smoke test', (WidgetTester tester) async {
    multiple_windows.main();
    await tester.pump(); // triggers a frame

    expect(
      find.widgetWithText(AppBar, 'Multi Window Reference App'),
      findsOneWidget,
    );
  });

  testWidgets('Can create a regular window', (WidgetTester tester) async {
    multiple_windows.main();
    await tester.pump(); // triggers a frame

    final toTap = find.widgetWithText(OutlinedButton, 'Regular');
    expect(toTap, findsOneWidget);
    await tester.tap(toTap);
    await tester.pump();

    expect(find.widgetWithText(AppBar, 'Regular Window'), findsOneWidget);
  });

  testWidgets('Can create a modeless dialog', (WidgetTester tester) async {
    multiple_windows.main();
    await tester.pump(); // triggers a frame

    final toTap = find.widgetWithText(OutlinedButton, 'Modeless Dialog');
    expect(toTap, findsOneWidget);
    await tester.tap(toTap);
    await tester.pump();

    expect(find.widgetWithText(AppBar, 'Dialog'), findsOneWidget);
  });

  testWidgets('Can create a modal dialog of a regular window', (
    WidgetTester tester,
  ) async {
    multiple_windows.main();
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

  testWidgets('Can close a modal dialog of a regular window', (
    WidgetTester tester,
  ) async {
    multiple_windows.main();
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

    final closeModalButton = find.widgetWithText(ElevatedButton, 'Close');
    expect(closeModalButton, findsOneWidget);
    await tester.tap(closeModalButton);
    await tester.pump();

    expect(find.widgetWithText(AppBar, 'Dialog'), findsNothing);
  });
}
