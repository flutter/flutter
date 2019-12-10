// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';

void main() {
  // Constants taken from _ContextMenuActionState.
  const Color _kBackgroundColor = Color(0xFFEEEEEE);
  const Color _kBackgroundColorPressed = Color(0xFFDDDDDD);

  Widget _getApp([VoidCallback onPressed]) {
    final UniqueKey actionKey = UniqueKey();
    final CupertinoContextMenuAction action = CupertinoContextMenuAction(
      key: actionKey,
      child: const Text('I am a CupertinoContextMenuAction'),
      onPressed: onPressed,
    );

    return CupertinoApp(
      home: CupertinoPageScaffold(
        child: Center(
          child: action,
        ),
      ),
    );
  }

  BoxDecoration _getDecoration(WidgetTester tester) {
    final Finder finder = find.descendant(
      of: find.byType(CupertinoContextMenuAction),
      matching: find.byType(Container),
    );
    expect(finder, findsOneWidget);
    final Container container = tester.widget(finder);
    return container.decoration;
  }

  testWidgets('responds to taps', (WidgetTester tester) async {
    bool wasPressed = false;
    await tester.pumpWidget(_getApp(() {
      wasPressed = true;
    }));

    expect(wasPressed, false);
    await tester.tap(find.byType(CupertinoContextMenuAction));
    expect(wasPressed, true);
  });

  testWidgets('turns grey when pressed and held', (WidgetTester tester) async {
    await tester.pumpWidget(_getApp());
    expect(_getDecoration(tester).color, _kBackgroundColor);

    final Offset actionCenter = tester.getCenter(find.byType(CupertinoContextMenuAction));
    final TestGesture gesture = await tester.startGesture(actionCenter);
    await tester.pump();
    expect(_getDecoration(tester).color, _kBackgroundColorPressed);

    await gesture.up();
    await tester.pump();
    expect(_getDecoration(tester).color, _kBackgroundColor);
  });
}
