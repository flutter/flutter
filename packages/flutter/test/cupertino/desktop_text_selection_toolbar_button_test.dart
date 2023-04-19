// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('can press', (WidgetTester tester) async {
    bool pressed = false;
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoDesktopTextSelectionToolbarButton(
            onPressed: () {
              pressed = true;
            },
            child: const Text('Tap me'),
          ),
        ),
      ),
    );

    expect(pressed, false);

    await tester.tap(find.byType(CupertinoDesktopTextSelectionToolbarButton));
    expect(pressed, true);
  });

  testWidgets('pressedOpacity defaults to 0.1', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        home: Center(
          child: CupertinoDesktopTextSelectionToolbarButton(
            onPressed: () { },
            child: const Text('Tap me'),
          ),
        ),
      ),
    );

    // Original at full opacity.
    FadeTransition opacity = tester.widget(find.descendant(
      of: find.byType(CupertinoDesktopTextSelectionToolbarButton),
      matching: find.byType(FadeTransition),
    ));
    expect(opacity.opacity.value, 1.0);

    // Make a "down" gesture on the button.
    final Offset center = tester.getCenter(find.byType(CupertinoDesktopTextSelectionToolbarButton));
    final TestGesture gesture = await tester.startGesture(center);
    await tester.pumpAndSettle();

    // Opacity reduces during the down gesture.
    opacity = tester.widget(find.descendant(
      of: find.byType(CupertinoDesktopTextSelectionToolbarButton),
      matching: find.byType(FadeTransition),
    ));
    expect(opacity.opacity.value, 0.7);

    // Release the down gesture.
    await gesture.up();
    await tester.pumpAndSettle();

    // Opacity is back to normal.
    opacity = tester.widget(find.descendant(
      of: find.byType(CupertinoDesktopTextSelectionToolbarButton),
      matching: find.byType(FadeTransition),
    ));
    expect(opacity.opacity.value, 1.0);
  });

  testWidgets('passing null to onPressed disables the button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const CupertinoApp(
        home: Center(
          child: CupertinoDesktopTextSelectionToolbarButton(
            onPressed: null,
            child: Text('Tap me'),
          ),
        ),
      ),
    );

    expect(find.byType(CupertinoButton), findsOneWidget);
    final CupertinoButton button = tester.widget(find.byType(CupertinoButton));
    expect(button.enabled, isFalse);
  });
}
