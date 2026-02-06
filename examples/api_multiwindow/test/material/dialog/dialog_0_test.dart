// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// ignore_for_file: invalid_use_of_internal_member

// ignore: avoid_relative_lib_imports
import '../../../lib/material/dialog/dialog.0.dart' as dialog_0;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/_features.dart' show isWindowingEnabled;

void main() {
  if (!isWindowingEnabled) {
    const String windowingDisabledErrorMessage = '''
Skipping dialog.0.dart because Windowing APIs are not enabled.

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

  testWidgets('Material dialog windowing smoke test', (
    WidgetTester tester,
  ) async {
    dialog_0.main();
    await tester.pump();

    expect(find.widgetWithText(AppBar, 'Dialog Sample'), findsOneWidget);
  });

  testWidgets('Can open typical material dialog', (WidgetTester tester) async {
    dialog_0.main();
    await tester.pump();

    final showDialogButton = find.widgetWithText(TextButton, 'Show Dialog');
    expect(showDialogButton, findsOneWidget);
    await tester.tap(showDialogButton);
    await tester.pump();

    expect(find.text('This is a typical dialog.'), findsOneWidget);
  });

  testWidgets('Can open fullscreen material dialog', (
    WidgetTester tester,
  ) async {
    dialog_0.main();
    await tester.pump();

    final showDialogButton = find.widgetWithText(
      TextButton,
      'Show Fullscreen Dialog',
    );
    expect(showDialogButton, findsOneWidget);
    await tester.tap(showDialogButton);
    await tester.pump();

    expect(find.text('This is a fullscreen dialog.'), findsOneWidget);
  });
}
